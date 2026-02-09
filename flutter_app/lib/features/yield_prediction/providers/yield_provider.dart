import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_app/core/api/agri_pulse_service.dart';
import 'package:flutter_app/features/dashboard/presentation/providers/weather_provider.dart';
import 'package:flutter_app/features/yield_prediction/domain/entities/yield_prediction.dart';
import 'package:flutter_app/core/localization/language_provider.dart';
import 'package:flutter_app/features/profile/providers/profile_provider.dart';
import 'package:flutter_app/features/auth/providers/auth_provider.dart';
import '../../../../core/services/local_vault.dart';
import 'package:flutter_app/features/yield_prediction/models/yield_record.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_app/core/api/path_enforcer.dart';

class YieldState {
  final bool isLoading;
  final String? errorMessage;
  final YieldPrediction? result;
  
  // Input fields
  final String? cropName;
  final String fieldName;
  final double? fieldArea;
  final String? soilType;
  final DateTime? plantedDate;
  final DateTime? expectedHarvestDate;
  final String? activeRecordId;

  const YieldState({
    this.isLoading = false,
    this.errorMessage,
    this.result,
    this.cropName,
    this.fieldName = '',
    this.fieldArea,
    this.soilType,
    this.plantedDate,
    this.expectedHarvestDate,
    this.activeRecordId,
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
    String? activeRecordId,
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
      activeRecordId: activeRecordId ?? this.activeRecordId,
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
  
  void loadRecord(YieldRecord record) {
    state = state.copyWith(
      activeRecordId: record.id,
      cropName: record.cropName,
      result: YieldPrediction.fromJson(record.id, record.rawAiResponse),
    );
  }

  Future<void> predictYield() async {
    if (state.cropName == null || state.fieldArea == null || state.soilType == null) {
      final tr = _ref.read(languageProvider.notifier);
      state = state.copyWith(errorMessage: tr.translate('select_params_warning'));
      return;
    }

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
        cropName: state.cropName!,
        fieldArea: state.fieldArea!,
        plantedDate: state.plantedDate?.toIso8601String() ?? DateTime.now().toIso8601String(),
        expectedHarvestDate: state.expectedHarvestDate?.toIso8601String(),
        soilType: state.soilType!,
        weatherForecast: weatherData,
        language: languageName,
      );

      if (response['status'] == 'success') {
        final prediction = YieldPrediction.fromJson(
          response['prediction_id'], 
          response['result']
        );

        final profileState = _ref.read(profileProvider);
        final activeField = profileState.selectedField;
        final activeCycleId = profileState.activeCycleId;

        // Save to History (Hierarchical)
        final record = YieldRecord(
          id: prediction.id,
          cropName: state.cropName!,
          fieldName: activeField?.name ?? state.fieldName,
          expectedYield: prediction.expectedYield,
          confidence: prediction.confidence,
          timestamp: DateTime.now(),
          rawAiResponse: response['result'],
          languageCode: currentLanguage.backendName,
        );

        if (activeField != null && activeCycleId != null) {
          final authState = _ref.read(authStateProvider);
          final userId = authState.value?.id ?? "anonymous";
          await LocalVault().saveYield(
            record, 
            userId: userId,
            fieldId: activeField.id, 
            cycleId: activeCycleId
          );
          
          // Auto-Refresh: Invalidate history provider to update dashboard immediately
          _ref.invalidate(yieldHistoryProvider);
        }

        state = state.copyWith(isLoading: false, result: prediction, activeRecordId: prediction.id);
      } else {
        throw Exception(response['error'] ?? "Unknown error from AI");
      }
    } catch (e) {
      debugPrint("Yield Error: $e");
      final tr = _ref.read(languageProvider.notifier);
      state = state.copyWith(
        isLoading: false, 
        errorMessage: "${tr.translate('yield_prediction_failed')}: ${e.toString()}"
      );
    }
  }

  Future<void> translateResult(String languageName, {String? recordId}) async {
    if (state.result == null && recordId == null) return;
    
    state = state.copyWith(isLoading: true, activeRecordId: recordId ?? state.activeRecordId);

    try {
      final currentResult = state.result!;
      
      // Combine text to translate into one block
      final factorsText = currentResult.primaryFactors.join("\n- ");
      final recsText = currentResult.recommendations.join("\n- ");
      final insightsText = currentResult.contextualInsights.map((e) => "${e.label}: ${e.value} (${e.status})").join("\n");
      final forecastText = currentResult.dailyForecast.map((e) => "${e.day}: ${e.condition}").join("\n");

      final fullTextToTranslate = """
      INSTRUCTION: Translate the following agricultural data into $languageName. 
      IMPORTANT: DO NOT translate or modify any text inside double brackets like [[TAG_NAME]]. Keep them exactly as they are.

      [[YIELD_FACTORS]]
      $factorsText

      [[YIELD_STRATEGY]]
      $recsText

      [[YIELD_INSIGHTS]]
      $insightsText

      [[YIELD_FORECAST]]
      $forecastText
      """;
      
      final translatedBlock = await _apiService.translateText(fullTextToTranslate, languageName);
      final String translatedStr = translatedBlock.toString();
      
      List<String> parseList(String tag) {
        final lines = translatedStr.split("\n");
        int startIndex = lines.indexWhere((l) => l.contains(tag));
        if (startIndex == -1) return [];
        
        final result = <String>[];
        for (int i = startIndex + 1; i < lines.length; i++) {
          final line = lines[i].trim();
          if (line.isEmpty) continue;
          if (line.startsWith("[[") && line.endsWith("]]")) break; 
          
          // Remove common bullet prefixes
          String clean = line.replaceFirst(RegExp(r'^[\-\*\•\d\.\)]+\s*'), '').trim();
          if (clean.isNotEmpty) result.add(clean);
        }
        return result;
      }
      
      final newFactors = parseList("[[YIELD_FACTORS]]");
      final newRecs = parseList("[[YIELD_STRATEGY]]");
      final insightLines = parseList("[[YIELD_INSIGHTS]]");
      final forecastLines = parseList("[[YIELD_FORECAST]]");
      
      // Map insights back
      final List<InsightCard> newInsights = [];
      for (int i = 0; i < currentResult.contextualInsights.length; i++) {
        final original = currentResult.contextualInsights[i];
        String newValue = original.value;
        String newStatus = original.status;
        
        for (final line in insightLines) {
          if (line.contains(original.label) || line.toLowerCase().contains(original.label.toLowerCase())) {
            final match = RegExp(r':\s*(.*?)\s*\((.*?)\)').firstMatch(line);
            if (match != null) {
              newValue = match.group(1)?.trim() ?? newValue;
              newStatus = match.group(2)?.trim() ?? newStatus;
            } else if (line.contains(":")) {
               newValue = line.split(":").last.trim();
            }
            break;
          }
        }
        newInsights.add(InsightCard(
          label: original.label,
          value: newValue,
          status: newStatus,
          iconType: original.iconType,
        ));
      }

      // Map forecast back
      final List<DailyForecast> newForecast = [];
      for (int i = 0; i < currentResult.dailyForecast.length; i++) {
        final original = currentResult.dailyForecast[i];
        String newDay = original.day;
        String newCondition = original.condition;
        
        if (i < forecastLines.length) {
          final line = forecastLines[i];
          if (line.contains(":")) {
            final parts = line.split(":");
            newDay = parts[0].trim();
            newCondition = parts.last.trim();
          }
        }
        newForecast.add(DailyForecast(
          day: newDay,
          temp: original.temp,
          condition: newCondition,
          yieldPotential: original.yieldPotential,
        ));
      }

      final newResult = YieldPrediction(
        id: currentResult.id,
        expectedYield: currentResult.expectedYield,
        confidence: currentResult.confidence,
        primaryFactors: newFactors.isNotEmpty ? newFactors : currentResult.primaryFactors,
        recommendations: newRecs.isNotEmpty ? newRecs : currentResult.recommendations,
        contextualInsights: newInsights.isNotEmpty ? newInsights : currentResult.contextualInsights,
        dailyForecast: newForecast.isNotEmpty ? newForecast : currentResult.dailyForecast,
        predictionDate: currentResult.predictionDate,
        rawAiResponse: currentResult.rawAiResponse,
      );

      state = state.copyWith(isLoading: false, result: newResult);
    } catch (e) {
      debugPrint("Translation Error: $e");
      state = state.copyWith(isLoading: false);
    }
  }

  void reset() {
    state = YieldState(plantedDate: DateTime.now().subtract(const Duration(days: 30)));
  }

  /// Delete a specific record
  Future<void> deleteRecord(String recordId) async {
    final authState = _ref.read(authStateProvider);
    final profileState = _ref.read(profileProvider);
    final userId = authState.value?.id;
    final fieldId = profileState.selectedFieldId;
    final cycleId = profileState.activeCycleId;

    if (userId != null && fieldId != null && cycleId != null) {
      final key = PathEnforcer.localCompositeKey(
        userId: userId,
        fieldId: fieldId,
        cycleId: cycleId,
        activityId: recordId,
      );
      await LocalVault().deleteYieldRecord(key);
      _ref.invalidate(yieldHistoryProvider);
      
      // If we deleted the active record, clear the state
      if (state.result?.id == recordId) {
        reset();
      }
    }
  }
}

final yieldProvider = StateNotifierProvider.autoDispose<YieldController, YieldState>((ref) {
  final apiService = ref.watch(agriPulseServiceProvider);
  return YieldController(apiService, ref);
});

final yieldHistoryProvider = FutureProvider.autoDispose<List<YieldRecord>>((ref) async {
  final profileState = ref.watch(profileProvider);
  final authState = ref.watch(authStateProvider);
  final userId = authState.value?.id;
  
  if (userId == null || profileState.selectedFieldId == null || profileState.activeCycleId == null) {
    return [];
  }

  return LocalVault().getYieldHistory(
    userId: userId,
    fieldId: profileState.selectedFieldId!,
    cycleId: profileState.activeCycleId!,
  );
});
