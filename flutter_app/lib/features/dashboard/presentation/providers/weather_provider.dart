import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/api/agri_pulse_service.dart';
import '../../../../core/services/local_vault.dart';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

// State class for Weather
class WeatherState {
  final bool isLoading;
  final Map<String, dynamic>? data;
  final String? error;

  WeatherState({
    this.isLoading = false,
    this.data,
    this.error,
  });

  factory WeatherState.initial() => WeatherState(isLoading: true);
  factory WeatherState.loading() => WeatherState(isLoading: true);
  factory WeatherState.success(Map<String, dynamic> data) => WeatherState(isLoading: false, data: data);
  factory WeatherState.error(String error) => WeatherState(isLoading: false, error: error);
}

// Coordinate class for default location (Namakkal, Tamil Nadu)
class Coordinates {
  final double lat;
  final double lon;
  
  const Coordinates(this.lat, this.lon);
}

const defaultLocation = Coordinates(11.2189, 78.1674); 

// Weather Provider
class WeatherNotifier extends StateNotifier<WeatherState> {
  final AgriPulseService _service;

  WeatherNotifier(this._service) : super(WeatherState.initial()) {
    initWeather(); 
  }

  Future<void> initWeather() async {
    try {
      final coords = await _determinePosition();
      await fetchWeather(coords: coords);
    } catch (e) {
      debugPrint("⚠️ Location Error: $e. Using default location.");
      await fetchWeather(coords: defaultLocation);
    }
  }

  /// Determine the current position of the device.
  ///
  /// When the location services are not enabled or permissions
  /// are denied the `Future` will return the default location.
  Future<Coordinates> _determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Test if location services are enabled.
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return defaultLocation;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return defaultLocation;
      }
    }
    
    if (permission == LocationPermission.deniedForever) {
      return defaultLocation;
    } 

    // When we reach here, permissions are granted and we can
    // continue accessing the position of the device.
    final position = await Geolocator.getCurrentPosition();
    return Coordinates(position.latitude, position.longitude);
  }

  Future<void> fetchWeather({Coordinates coords = defaultLocation}) async {
    final locationKey = "${coords.lat}_${coords.lon}";
    state = WeatherState.loading();

    try {
      final data = await _service.getCurrentWeather(coords.lat, coords.lon);
      
      // Cache success result
      await LocalVault().cacheWeather(locationKey, jsonEncode(data));
      
      state = WeatherState.success(data);
    } catch (e) {
      debugPrint("❌ Weather API failed: $e. Using cache...");
      
      // Fallback to cache
      final cached = LocalVault().getCachedWeather(locationKey);
      if (cached != null) {
        state = WeatherState.success(jsonDecode(cached.jsonData));
      } else {
        state = WeatherState.error("No network & no cached data.");
      }
    }
  }
}

final weatherProvider = StateNotifierProvider<WeatherNotifier, WeatherState>((ref) {
  final service = ref.watch(agriPulseServiceProvider);
  return WeatherNotifier(service);
});
