import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'package:mockito/mockito.dart';
import 'package:flutter_app/core/services/local_vault.dart';
import 'package:flutter_app/core/api/agri_pulse_service.dart';
import 'package:flutter_app/features/dashboard/presentation/providers/weather_provider.dart';
import 'package:flutter_app/features/crop_diagnosis/presentation/crop_doctor_screen.dart';

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

      final tempDir = Directory.systemTemp.createTempSync();
      Hive.init(tempDir.path);
      await LocalVault().init();

      binding.platformDispatcher.implicitView!.physicalSize = const Size(1920, 1080);
      binding.platformDispatcher.implicitView!.devicePixelRatio = 1.0;
    });

  tearDown(() {
    final binding = TestWidgetsFlutterBinding.ensureInitialized();
    binding.platformDispatcher.implicitView!.resetPhysicalSize();
    binding.platformDispatcher.implicitView!.resetDevicePixelRatio();
  });

  group('CropDoctorScreen Widget Tests', () {
    testWidgets('should display title and instructions', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            agriPulseServiceProvider.overrideWithValue(mockApiService),
            weatherProvider.overrideWith((ref) => WeatherNotifierMock(mockApiService)),
          ],
          child: const MaterialApp(
            home: CropDoctorScreen(),
          ),
        ),
      );

      await tester.pump(const Duration(seconds: 1));
      expect(find.text('Crop Doctor'), findsOneWidget);
      expect(find.text('Take a clear photo of the affected area'), findsOneWidget);
    });

    testWidgets('should show image picker in empty state', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            agriPulseServiceProvider.overrideWithValue(mockApiService),
            weatherProvider.overrideWith((ref) => WeatherNotifierMock(mockApiService)),
          ],
          child: const MaterialApp(
            home: CropDoctorScreen(),
          ),
        ),
      );
      
      await tester.pump(const Duration(seconds: 1));

      expect(find.text('Upload Image'), findsOneWidget);
      expect(find.text('Camera'), findsOneWidget);
      expect(find.text('Gallery'), findsOneWidget);
      expect(find.byIcon(Icons.add_a_photo_outlined), findsOneWidget);
    });

    testWidgets('should not show Analyze button in empty state', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            agriPulseServiceProvider.overrideWithValue(mockApiService),
            weatherProvider.overrideWith((ref) => WeatherNotifierMock(mockApiService)),
          ],
          child: const MaterialApp(
            home: CropDoctorScreen(),
          ),
        ),
      );
      
      await tester.pump(const Duration(seconds: 1));

      // Analyze button should not exist when no image is selected
      expect(find.text('Analyze Crop'), findsNothing);
    });

    testWidgets('Camera button should be tappable', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            agriPulseServiceProvider.overrideWithValue(mockApiService),
            weatherProvider.overrideWith((ref) => WeatherNotifierMock(mockApiService)),
          ],
          child: const MaterialApp(
            home: CropDoctorScreen(),
          ),
        ),
      );
      
      await tester.pump(const Duration(seconds: 1));

      final cameraButton = find.text('Camera');
      expect(cameraButton, findsOneWidget);
      
      // Verify button is tappable (actual picker won't open in tests)
      await tester.tap(cameraButton);
      await tester.pump(const Duration(seconds: 1));
      
      // No error should occur
    });

    testWidgets('Gallery button should be tappable', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            agriPulseServiceProvider.overrideWithValue(mockApiService),
            weatherProvider.overrideWith((ref) => WeatherNotifierMock(mockApiService)),
          ],
          child: const MaterialApp(
            home: CropDoctorScreen(),
          ),
        ),
      );
      
      await tester.pump(const Duration(seconds: 1));

      final galleryButton = find.text('Gallery');
      expect(galleryButton, findsOneWidget);
      
      await tester.tap(galleryButton);
      await tester.pump(const Duration(seconds: 1));
      
      // No error should occur
    });

    testWidgets('back button should be present', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            agriPulseServiceProvider.overrideWithValue(mockApiService),
            weatherProvider.overrideWith((ref) => WeatherNotifierMock(mockApiService)),
          ],
          child: const MaterialApp(
            home: CropDoctorScreen(),
          ),
        ),
      );

      await tester.pump(const Duration(seconds: 1));
      expect(find.byIcon(Icons.arrow_back_ios_new_rounded), findsOneWidget);
    });

    testWidgets('should display support text', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            agriPulseServiceProvider.overrideWithValue(mockApiService),
            weatherProvider.overrideWith((ref) => WeatherNotifierMock(mockApiService)),
          ],
          child: const MaterialApp(
            home: CropDoctorScreen(),
          ),
        ),
      );
      
      await tester.pumpAndSettle();

      expect(find.text('Supports: JPG, PNG'), findsOneWidget);
    });
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
