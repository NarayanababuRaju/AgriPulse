import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter_app/core/services/local_vault.dart';
import 'package:flutter_app/features/dashboard/presentation/farmer_dashboard_screen.dart';
import 'package:flutter_app/features/crop_diagnosis/presentation/crop_doctor_screen.dart';
import 'package:flutter_app/features/yield_prediction/presentation/screens/yield_prediction_screen.dart';
import 'package:flutter_app/features/dashboard/presentation/screens/activity_history_screen.dart';
import 'package:flutter_app/features/profile/domain/entities/field.dart';
import 'package:flutter_app/features/dashboard/presentation/providers/weather_provider.dart';
import 'package:flutter_app/core/api/agri_pulse_service.dart';

import '../unit/auth_provider_test.mocks.dart';

void main() {
  late Directory tempDir;
  late MockAgriPulseService mockApiService;

  setUp(() async {
    final binding = TestWidgetsFlutterBinding.ensureInitialized();
    // Default to iPhone SE size for overflow detection
    binding.platformDispatcher.implicitView!.physicalSize = const Size(320, 568);
    binding.platformDispatcher.implicitView!.devicePixelRatio = 1.0;

    tempDir = Directory.systemTemp.createTempSync();
    Hive.init(tempDir.path);
    await LocalVault().init();
    
    // Seed a field to avoid onboarding redirects
    await LocalVault().saveFields('1', [
      const Field(id: 'field_1', name: 'Demo Plot', soilType: 'Red', acreage: 2.0, irrigationType: 'Drip')
    ]);
    await LocalVault().saveSelectedFieldId('1', 'field_1');

    mockApiService = MockAgriPulseService();
  });

  tearDown(() async {
    final binding = TestWidgetsFlutterBinding.ensureInitialized();
    binding.platformDispatcher.implicitView!.resetPhysicalSize();
    binding.platformDispatcher.implicitView!.resetDevicePixelRatio();
    await Hive.close();
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  Widget createTestWidget(Widget child) {
    return ProviderScope(
      overrides: [
        agriPulseServiceProvider.overrideWithValue(mockApiService),
        weatherProvider.overrideWith((ref) => WeatherNotifierMock(mockApiService)),
      ],
      child: MaterialApp(
        home: child,
      ),
    );
  }

  group('UI Overflow Audit - Small Screen (320x568)', () {
    testWidgets('Dashboard should not have overflows', (tester) async {
      await tester.pumpWidget(createTestWidget(const FarmerDashboardScreen()));
      await tester.pump(const Duration(seconds: 1));
      expect(tester.takeException(), isNull);
    });

    testWidgets('Crop Doctor should not have overflows', (tester) async {
      await tester.pumpWidget(createTestWidget(const CropDoctorScreen()));
      await tester.pump(const Duration(seconds: 1));
      expect(tester.takeException(), isNull);
    });

    testWidgets('Yield Prediction should not have overflows', (tester) async {
      await tester.pumpWidget(createTestWidget(const YieldPredictionScreen()));
      await tester.pump(const Duration(seconds: 1));
      expect(tester.takeException(), isNull);
    });

    testWidgets('Activity History should not have overflows', (tester) async {
      await tester.pumpWidget(createTestWidget(const ActivityHistoryScreen()));
      await tester.pump(const Duration(seconds: 1));
      expect(tester.takeException(), isNull);
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
}
