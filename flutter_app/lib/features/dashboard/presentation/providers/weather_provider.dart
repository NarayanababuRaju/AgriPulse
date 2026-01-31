import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/api/agri_pulse_service.dart';

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
    fetchWeather(); // Fetch immediately on init
  }

  Future<void> fetchWeather({Coordinates coords = defaultLocation}) async {
    state = WeatherState.loading();
    try {
      final data = await _service.getCurrentWeather(coords.lat, coords.lon);
      state = WeatherState.success(data);
    } catch (e) {
      state = WeatherState.error(e.toString());
    }
  }
}

final weatherProvider = StateNotifierProvider<WeatherNotifier, WeatherState>((ref) {
  final service = ref.watch(agriPulseServiceProvider);
  return WeatherNotifier(service);
});
