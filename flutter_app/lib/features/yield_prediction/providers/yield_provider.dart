import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_app/core/api/agri_pulse_service.dart';
import 'package:flutter_app/features/dashboard/presentation/providers/weather_provider.dart';
import 'package:flutter_app/features/yield_prediction/domain/entities/yield_prediction.dart';
import 'package:flutter_app/features/yield_prediction/providers/language_provider.dart';
import 'package:flutter_app/core/services/local_vault.dart';
import 'package:flutter_app/features/yield_prediction/models/yield_record.dart';
import 'package:flutter/foundation.dart';

class YieldState {
  final bool isLoading;
  final String? errorMessage;
  final YieldPrediction? result;
  
  // Input fields
  final String cropName;
  final String fieldName;
  final double fieldArea;
  final String soilType;
  final DateTime? plantedDate;
  final DateTime? expectedHarvestDate;

  const YieldState({
    this.isLoading = false,
    this.errorMessage,
    this.result,
    this.cropName = 'Onion',
    this.fieldName = '',
    this.fieldArea = 1.0,
    this.soilType = 'Clay Loam',
    this.plantedDate,
    this.expectedHarvestDate,
  });

  YieldState copyWith({
    bool? isLoading,
    String? errorMessage,
    YieldPrediction? result,
    String? cropName,
    String? fieldName,
    double? fieldArea,
    String? soilType,
    DateTime? plantedDate,
    DateTime? expectedHarvestDate,
  }) {
    return YieldState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage ?? this.errorMessage,
      result: result ?? this.result,
      cropName: cropName ?? this.cropName,
      fieldName: fieldName ?? this.fieldName,
      fieldArea: fieldArea ?? this.fieldArea,
      soilType: soilType ?? this.soilType,
      plantedDate: plantedDate ?? this.plantedDate,
      expectedHarvestDate: expectedHarvestDate ?? this.expectedHarvestDate,
    );
  }
}

class YieldController extends StateNotifier<YieldState> {
  final AgriPulseService _apiService;
  final Ref _ref;

  YieldController(this._apiService, this._ref) : super(YieldState(plantedDate: DateTime.now().subtract(const Duration(days: 30))));

  void updateCropName(String value) => state = state.copyWith(cropName: value);
  void updateFieldName(String value) => state = state.copyWith(fieldName: value);
  void updateFieldArea(double value) => state = state.copyWith(fieldArea: value);
  void updateSoilType(String value) => state = state.copyWith(soilType: value);
  void updatePlantedDate(DateTime value) => state = state.copyWith(plantedDate: value);
  void updateExpectedHarvestDate(DateTime value) => state = state.copyWith(expectedHarvestDate: value);

  Future<void> predictYield() async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      final weatherState = _ref.read(weatherProvider);
      // Backend expects a JSON string of weather forecast
      final weatherData = weatherState.data ?? {};
      
      final currentLanguage = _ref.read(languageProvider);
      final languageName = currentLanguage == AppLanguage.en ? "English" : 
                           currentLanguage == AppLanguage.hi ? "Hindi" :
                           currentLanguage == AppLanguage.ta ? "Tamil" :
                           currentLanguage == AppLanguage.kn ? "Kannada" :
                           currentLanguage == AppLanguage.te ? "Telugu" : "Malayalam";

      final response = await _apiService.predictYield(
        farmerId: "demo-farmer-123", // MVP Hardcoded
        cropName: state.cropName,
        fieldArea: state.fieldArea,
        plantedDate: state.plantedDate?.toIso8601String() ?? DateTime.now().toIso8601String(),
        expectedHarvestDate: state.expectedHarvestDate?.toIso8601String(),
        soilType: state.soilType,
        weatherForecast: weatherData,
        language: languageName,
      );

      if (response['status'] == 'success') {
        final prediction = YieldPrediction.fromJson(
          response['prediction_id'], 
          response['result']
        );

        // Save to History
        final record = YieldRecord(
          id: prediction.id,
          cropName: state.cropName,
          fieldName: state.fieldName,
          expectedYield: prediction.expectedYield,
          confidence: prediction.confidence,
          timestamp: DateTime.now(),
          rawAiResponse: response['result'],
        );
        await LocalVault().saveYield(record);

        state = state.copyWith(isLoading: false, result: prediction);
      } else {
        throw Exception(response['error'] ?? "Unknown error from AI");
      }
    } catch (e) {
      debugPrint("Yield Error: $e");
      state = state.copyWith(
        isLoading: false, 
        errorMessage: "Yield prediction failed: ${e.toString()}"
      );
    }
  }

  Future<void> translateResult(String languageName) async {
    if (state.result == null) return;
    
    state = state.copyWith(isLoading: true);

    try {
      final currentResult = state.result!;
      
      // Combine text to translate into one block to save API calls
      // Format: "Factors: ... | Recommendations: ..."
      final factorsText = currentResult.primaryFactors.join(" || ");
      final recsText = currentResult.recommendations.join(" || ");
      
      final fullTextToTranslate = "FACTORS_START\n$factorsText\nFACTORS_END\nRECOMMENDATIONS_START\n$recsText\nRECOMMENDATIONS_END";
      
      final translatedBlock = await _apiService.translateText(fullTextToTranslate, languageName);
      
      // Parse back
      final factorsMatch = RegExp(r'FACTORS_START\n(.*?)\nFACTORS_END', dotAll: true).firstMatch(translatedBlock);
      final recsMatch = RegExp(r'RECOMMENDATIONS_START\n(.*?)\nRECOMMENDATIONS_END', dotAll: true).firstMatch(translatedBlock);
      
      final newFactors = factorsMatch?.group(1)?.split(" || ").map((e) => e.trim()).toList() ?? currentResult.primaryFactors;
      final newRecs = recsMatch?.group(1)?.split(" || ").map((e) => e.trim()).toList() ?? currentResult.recommendations;
      
      final newResult = YieldPrediction(
        id: currentResult.id,
        expectedYield: currentResult.expectedYield,
        confidence: currentResult.confidence,
        primaryFactors: newFactors,
        recommendations: newRecs,
        contextualInsights: currentResult.contextualInsights,
        dailyForecast: currentResult.dailyForecast,
        predictionDate: currentResult.predictionDate,
        rawAiResponse: currentResult.rawAiResponse,
      );

      state = state.copyWith(isLoading: false, result: newResult);
    } catch (e) {
      debugPrint("Translation Error: $e");
      // Don't fail the whole state, just stop loading
      state = state.copyWith(isLoading: false);
    }
  }

  void reset() {
    state = YieldState(plantedDate: DateTime.now().subtract(const Duration(days: 30)));
  }
}

final yieldProvider = StateNotifierProvider.autoDispose<YieldController, YieldState>((ref) {
  final apiService = ref.watch(agriPulseServiceProvider);
  return YieldController(apiService, ref);
});

final yieldHistoryProvider = FutureProvider<List<YieldRecord>>((ref) async {
  return LocalVault().getYieldHistory();
});
