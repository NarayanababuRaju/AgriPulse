import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http_parser/http_parser.dart'; // For MediaType
import 'dart:math' as math;
import '../../features/profile/providers/profile_provider.dart';

import 'api_client.dart';

/// AgriPulse API Service
/// 
/// Handles all backend communication for Crop Diagnosis and User Data.
class AgriPulseService {
  final Dio _dio;
  final Ref _ref;
  
  AgriPulseService(this._dio, this._ref);

  /// Analyze Crop Image (Hierarchical AI Implementation)
  /// 
  /// Converts photo to base64, grounds prompt in plot metadata, 
  /// and executes Gemini 2.5 call with exponential backoff.
  Future<Map<String, dynamic>> analyzeCrop(
    XFile imageFile, 
    String farmerId, 
    String voiceTranscription, 
    {Map<String, dynamic>? weatherContext, 
    String? languageCode,
    String? irrigationStage,
    String? soilMoisture,
    String? weatherEvent,
    String? spreadPattern,
    String? lastTreatment,
    String? dosage,
    }) async {
    try {
      return await _withRetry(() async {
        // 1. Resolve Hierarchical Context automatically
        final profile = _ref.read(profileProvider);
        final activeField = profile.selectedField;
        final activeCycleId = profile.activeCycleId;
        
        final String fieldId = activeField?.id ?? "unassigned_field";
        final String cycleId = activeCycleId ?? "default_cycle";
        final double acreage = activeField?.acreage ?? 1.0;
        final String soilType = activeField?.soilType ?? "Unknown";

        // 2. Prepare MultiModal Payload for Backend
        final bytes = await imageFile.readAsBytes();
        
        FormData formData = FormData.fromMap({
          "farmer_id": farmerId,
          "field_id": fieldId,
          "cycle_id": cycleId,
          "image": MultipartFile.fromBytes(bytes, filename: "crop.jpg", contentType: MediaType("image", "jpeg")),
          "voice_transcription": voiceTranscription,
          "acreage": acreage,
          "soil_type": soilType,
          if (weatherContext != null) "weather_context": jsonEncode(weatherContext),
          if (languageCode != null) "language": languageCode,
          if (irrigationStage != null) "irrigation_stage": irrigationStage,
          if (soilMoisture != null) "soil_moisture": soilMoisture,
          if (weatherEvent != null) "weather_event": weatherEvent,
          if (spreadPattern != null) "spread_pattern": spreadPattern,
          if (lastTreatment != null) "last_treatment": lastTreatment,
          if (dosage != null) "dosage": dosage,
        });

      // 3. Call Backend API (instead of direct Gemini)
      // This ensures hierarchical persistence and prompt grounding in the backend
        final response = await _dio.post(
          '/api/crop/analyze',
          data: formData,
        );

        return response.data;
      });
    } catch (e) {
       if (e is DioException) {
         throw Exception("API Error: ${e.response?.data?['detail'] ?? e.message}");
       }
       throw Exception("Analysis failed: $e");
    }
  }

  /// Exponential Backoff Retry Utility
  Future<T> _withRetry<T>(Future<T> Function() action) async {
    int retries = 0;
    int maxRetries = 5;
    
    while (true) {
      try {
        return await action();
      } catch (e) {
        retries++;
        if (retries >= maxRetries) {
          rethrow;
        }
        // Wait: 2s, 4s, 8s, 16s...
        final waitSeconds = math.pow(2, retries).toInt();
        await Future.delayed(Duration(seconds: waitSeconds));
      }
    }
  }
  /// Get Weather Forecast (7-Day)
  ///
  /// Fetches daily forecast for the given coordinates.
  Future<Map<String, dynamic>> getForecast(double lat, double lon) async {
    try {
      final response = await _dio.get(
        '/api/weather/forecast',
        queryParameters: {
          'lat': lat,
          'lon': lon,
        },
      );
      return response.data;
    } catch (e) {
      if (e is DioException) {
         throw Exception("Forecast API Error: ${e.message}");
      }
      throw Exception("Forecast fetch failed: $e");
    }
  }

  /// Get Current Weather
  /// 
  /// Fetches real-time weather for the given coordinates.
  Future<Map<String, dynamic>> getCurrentWeather(double lat, double lon) async {
    try {
      final response = await _dio.get(
        '/api/weather/current',
        queryParameters: {
          'lat': lat,
          'lon': lon,
        },
      );
      return response.data;
    } catch (e) {
      if (e is DioException) {
         // Silently fail for weather, return null or throw? 
         // Throwing allows UI to handle it (e.g. show cached/default)
         throw Exception("Weather API Error: ${e.message}");
      }
      throw Exception("Weather fetch failed: $e");
    }
  }

  /// Synthesize Speech from Text
  /// 
  /// Returns audio bytes (MP3) from the backend TTS service.
  Future<List<int>> synthesizeSpeech(String text, String languageCode) async {
    try {
      FormData formData = FormData.fromMap({
        "text": text,
        "language": languageCode,
      });

      final response = await _dio.post(
        '/api/speech/synthesize',
        data: formData,
        options: Options(responseType: ResponseType.bytes),
      );

      return response.data;
    } catch (e) {
      if (e is DioException) {
        throw Exception("API Error: ${e.response?.data?['detail'] ?? e.message}");
      }
      throw Exception("Speech fetch failed: $e");
    }
  }

  /// Predict Crop Yield
  /// 
  /// Calls Gemini 3.0 Pro reasoning for yield prediction.
  Future<Map<String, dynamic>> predictYield({
    required String farmerId,
    required String cropName,
    required double fieldArea,
    required String plantedDate,
    required String soilType,
    required Map<String, dynamic> weatherForecast,
    String? expectedHarvestDate,
    String? language,
  }) async {
    try {
      final profile = _ref.read(profileProvider);
      final fieldId = profile.selectedFieldId ?? "unassigned_field";
      final cycleId = profile.activeCycleId ?? "default_cycle";

      FormData formData = FormData.fromMap({
        "farmer_id": farmerId,
        "field_id": fieldId,
        "cycle_id": cycleId,
        "crop_name": cropName,
        "field_area": fieldArea,
        "planted_date": plantedDate,
        "expected_harvest_date": expectedHarvestDate,
        "soil_type": soilType,
        "weather_forecast": jsonEncode(weatherForecast),
        if (language != null) "language": language,
      });

      final response = await _dio.post(
        '/api/crop/predict-yield',
        data: formData,
      );

      return response.data;
    } catch (e) {
      if (e is DioException) {
        throw Exception("API Error: ${e.response?.data?['detail'] ?? e.message}");
      }
      throw Exception("Yield prediction failed: $e");
    }
  }

  /// Translate Text
  /// 
  /// Uses Gemini Flash for fast content translation.
  Future<String> translateText(String text, String targetLanguage) async {
    try {
      FormData formData = FormData.fromMap({
        "text": text,
        "target_language": targetLanguage,
      });

      final response = await _dio.post(
        '/api/utils/translate',
        data: formData,
      );

      return response.data['translation'];
    } catch (e) {
      if (e is DioException) {
        throw Exception("API Error: ${e.response?.data?['detail'] ?? e.message}");
      }
      throw Exception("Translation failed: $e");
    }
  }

  /// Refine Diagnosis (Conversational)
  ///
  /// Sends farmer's feedback and context to re-evaluate diagnosis.
  Future<Map<String, dynamic>> refineDiagnosis({
    required String farmerId,
    required Map<String, dynamic> originalDiagnosis,
    required String feedback,
    required Map<String, dynamic> contextOverrides,
    List<Map<String, dynamic>>? interactionHistory,
    String? language,
  }) async {
    try {
      final profile = _ref.read(profileProvider);
      final fieldId = profile.selectedFieldId ?? "unassigned_field";
      final cycleId = profile.activeCycleId ?? "default_cycle";

      final response = await _dio.post(
        '/api/crop/refine',
        data: {
          "farmer_id": farmerId,
          "field_id": fieldId,
          "cycle_id": cycleId,
          "original_diagnosis": originalDiagnosis,
          "farmer_feedback": feedback,
          "context_overrides": contextOverrides,
          "interaction_history": interactionHistory,
          "language": language,
        },
      );
      return response.data;
    } catch (e) {
      if (e is DioException) {
        throw Exception("API Error: ${e.response?.data?['detail'] ?? e.message}");
      }
      throw Exception("Refinement failed: $e");
    }
  }
}

final agriPulseServiceProvider = Provider<AgriPulseService>((ref) {
  final dio = ref.watch(apiClientProvider);
  return AgriPulseService(dio, ref);
});
