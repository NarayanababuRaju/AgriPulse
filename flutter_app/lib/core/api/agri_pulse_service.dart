import 'dart:io';
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http_parser/http_parser.dart'; // For MediaType

import 'api_client.dart';

/// AgriPulse API Service
/// 
/// Handles all backend communication for Crop Diagnosis and User Data.
class AgriPulseService {
  final Dio _dio;

  AgriPulseService(this._dio);

  /// Analyze Crop Image
  /// 
  /// Uploads an image to the backend for Gemini 3 diagnosis.
  Future<Map<String, dynamic>> analyzeCrop(XFile imageFile, String farmerId, String voiceTranscription, {Map<String, dynamic>? weatherContext, String? languageCode}) async {
    try {
      String fileName = imageFile.path.split('/').last;
      
      // Read bytes directly for web compatibility
      final bytes = await imageFile.readAsBytes();
      
      FormData formData = FormData.fromMap({
        "image": MultipartFile.fromBytes(
          bytes,
          filename: fileName,
          contentType: MediaType('image', 'jpeg'),
        ),
        "farmer_id": farmerId,
        "voice_transcription": voiceTranscription,
        if (weatherContext != null) "weather_context": jsonEncode(weatherContext), 
        if (languageCode != null) "language": languageCode,
      });

      final response = await _dio.post(
        '/api/crop/analyze', // Corrected endpoint
        data: formData,
      );

      return response.data;
    } catch (e) {
      if (e is DioException) {
        throw Exception("API Error: ${e.message}");
      }
      throw Exception("Upload failed: $e");
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
        throw Exception("Speech synthesis failed: ${e.message}");
      }
      throw Exception("Speech fetch failed: $e");
    }
  }
}

final agriPulseServiceProvider = Provider<AgriPulseService>((ref) {
  final dio = ref.watch(apiClientProvider);
  return AgriPulseService(dio);
});
