import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:mockito/mockito.dart';
import 'package:flutter_app/core/services/local_vault.dart';
import 'package:flutter_app/core/api/agri_pulse_service.dart';
import 'package:flutter_app/features/dashboard/presentation/providers/weather_provider.dart';
import 'package:flutter_app/features/yield_prediction/presentation/screens/yield_prediction_screen.dart';

import '../unit/auth_provider_test.mocks.dart';

void main() {
    late MockAgriPulseService mockApiService;

    setUp(() async {
      final binding = TestWidgetsFlutterBinding.ensureInitialized();
      mockApiService = MockAgriPulseService();
      when(mockApiService.getForecast(11.2189, 78.1674)).thenAnswer((_) async => {
        'daily_summary': List.generate(7, (i) => {
          'time': '2026-02-1$i',
          'condition': 'Sunny',
          'temp': 28.0 + i,
        })
      });

      binding.platformDispatcher.implicitView!.physicalSize = const Size(1920, 1080);
      binding.platformDispatcher.implicitView!.devicePixelRatio = 1.0;
      
      final tempDir = Directory.systemTemp.createTempSync();
      Hive.init(tempDir.path);
      await LocalVault().init();
    });

  tearDown(() {
    final binding = TestWidgetsFlutterBinding.ensureInitialized();
    binding.platformDispatcher.implicitView!.resetPhysicalSize();
    binding.platformDispatcher.implicitView!.resetDevicePixelRatio();
  });

  testWidgets('YieldPredictionScreen renders correctly', (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          agriPulseServiceProvider.overrideWithValue(mockApiService),
          weatherProvider.overrideWith((ref) => WeatherNotifierMock(mockApiService)),
        ],
        child: const MaterialApp(
          home: YieldPredictionScreen(),
        ),
      ),
    );

    // Wait for fade animations
    await tester.pump(const Duration(seconds: 1));

    // Verify critical UI elements are present
    expect(find.text('Yield Prediction'), findsOneWidget); // App Bar Title
    expect(find.text('FIELD PARAMETERS'), findsOneWidget); // Section Header
    expect(find.text('Field Area (Acres)'), findsOneWidget); // Input Label
    
    // Check if the "Run Prediction" button exists
    expect(find.text('Run Prediction'), findsOneWidget);
  });
}

class WeatherNotifierMock extends WeatherNotifier {
  WeatherNotifierMock(AgriPulseService api) : super(api) {
    state = WeatherState.success({
      'condition': 'Sunny',
      'temperature': 28,
      'location': 'Namakkal, Tamil Nadu',
    });
  }

  @override
  Future<void> initWeather() async {}

  @override
  Future<void> fetchWeather({Coordinates coords = defaultLocation}) async {}
}
