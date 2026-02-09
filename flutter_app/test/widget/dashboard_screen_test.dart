import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'package:mockito/mockito.dart';
import 'package:flutter_app/core/services/local_vault.dart';
import 'package:flutter_app/core/api/agri_pulse_service.dart';
import 'package:flutter_app/features/dashboard/presentation/farmer_dashboard_screen.dart';
import 'package:flutter_app/features/dashboard/presentation/providers/weather_provider.dart';
import 'package:flutter_app/features/dashboard/presentation/providers/activity_provider.dart';
import 'package:flutter_app/features/dashboard/presentation/widgets/action_card.dart';
import 'package:flutter_app/features/dashboard/presentation/widgets/recent_activity_list.dart';
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

  group('FarmerDashboardScreen Widget Tests', () {
    testWidgets('should display weather card', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            agriPulseServiceProvider.overrideWithValue(mockApiService),
            weatherProvider.overrideWith((ref) => WeatherNotifierMock(mockApiService)),
            dashboardActivityProvider.overrideWith((ref) => Future.value([])),
          ],
          child: const MaterialApp(
            home: FarmerDashboardScreen(),
          ),
        ),
      );
      
      await tester.pump(const Duration(seconds: 1));

      // Weather card content (Updated to match Namakkal default)
      expect(find.text('Namakkal, Tamil Nadu'), findsOneWidget);
      expect(find.text('28°'), findsOneWidget);
      expect(find.text('Sunny'), findsOneWidget);
    });

    testWidgets('should display AI Agri Tools section', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            agriPulseServiceProvider.overrideWithValue(mockApiService),
            weatherProvider.overrideWith((ref) => WeatherNotifierMock(mockApiService)),
            dashboardActivityProvider.overrideWith((ref) => Future.value([])),
          ],
          child: const MaterialApp(
            home: FarmerDashboardScreen(),
          ),
        ),
      );
      
      await tester.pump(const Duration(seconds: 1));

      expect(find.text('Smart Tools'), findsOneWidget);
      expect(find.text('Crop Doctor'), findsOneWidget);
      expect(find.text('Yield Est.'), findsOneWidget);
    });

    testWidgets('should display recent activity section', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            agriPulseServiceProvider.overrideWithValue(mockApiService),
            weatherProvider.overrideWith((ref) => WeatherNotifierMock(mockApiService)),
            dashboardActivityProvider.overrideWith((ref) => Future.value([])),
          ],
          child: const MaterialApp(
            home: FarmerDashboardScreen(),
          ),
        ),
      );
      
      await tester.pump(const Duration(seconds: 1));

      expect(find.text('Recent Activity'), findsOneWidget);
      expect(find.text('No activity yet'), findsOneWidget);
    });

    testWidgets('should have profile icon button', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            agriPulseServiceProvider.overrideWithValue(mockApiService),
            weatherProvider.overrideWith((ref) => WeatherNotifierMock(mockApiService)),
            dashboardActivityProvider.overrideWith((ref) => Future.value([])),
          ],
          child: const MaterialApp(
            home: FarmerDashboardScreen(),
          ),
        ),
      );
      
      await tester.pump(const Duration(seconds: 1));

      expect(find.byIcon(Icons.person), findsOneWidget);
    });

    testWidgets('should render mobile-friendly vertical layout on small screens', (tester) async {
      final binding = TestWidgetsFlutterBinding.ensureInitialized();
      binding.platformDispatcher.implicitView!.physicalSize = const Size(400, 1200);
      binding.platformDispatcher.implicitView!.devicePixelRatio = 1.0;
      
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            agriPulseServiceProvider.overrideWithValue(mockApiService),
            weatherProvider.overrideWith((ref) => WeatherNotifierMock(mockApiService)),
            dashboardActivityProvider.overrideWith((ref) => Future.value([])),
          ],
          child: const MaterialApp(
            home: FarmerDashboardScreen(),
          ),
        ),
      );
      
      await tester.pump(const Duration(seconds: 1));

      // In mobile view, elements should still be present but stacked
      expect(find.text('Namakkal, Tamil Nadu'), findsOneWidget);
      expect(find.text('Smart Tools'), findsOneWidget);
      expect(find.text('Recent Activity'), findsOneWidget);
      
      // Cleanup for other tests
      binding.platformDispatcher.implicitView!.physicalSize = const Size(1920, 1080);
    });
  });

  // group('WeatherCard Widget Tests', () {
  //   testWidgets('should render weather information', (tester) async {
  //     await tester.pumpWidget(
  //       MaterialApp(
  //         home: Scaffold(
  //           body: WeatherCard(location: 'Namakkal, Tamil Nadu'),
  //         ),
  //       ),
  //     );
  //
  //     expect(find.text('Namakkal, Tamil Nadu'), findsOneWidget);
  //     expect(find.text('28°'), findsOneWidget);
  //     expect(find.text('Sunny'), findsOneWidget);
  //     expect(find.byIcon(Icons.wb_sunny_rounded), findsOneWidget);
  //   });
  // });

  group('ActionCard Widget Tests', () {
    testWidgets('should render action card with title and icon', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ActionCard(
              title: 'Test Action',
              icon: Icons.check,
              color: Colors.blue,
              onTap: () {},
            ),
          ),
        ),
      );

      expect(find.text('Test Action'), findsOneWidget);
      expect(find.byIcon(Icons.check), findsOneWidget);
    });

    testWidgets('should render action card with subtitle', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ActionCard(
              title: 'Test Title',
              subtitle: 'Detailed instruction or hint',
              icon: Icons.info,
              color: Colors.green,
              onTap: () {},
            ),
          ),
        ),
      );

      expect(find.text('Detailed instruction or hint'), findsOneWidget);
    });

    testWidgets('should be tappable', (tester) async {
      var tapped = false;
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ActionCard(
              title: 'Test Action',
              icon: Icons.check,
              color: Colors.blue,
              onTap: () => tapped = true,
            ),
          ),
        ),
      );

      await tester.tap(find.byType(ActionCard));
      expect(tapped, isTrue);
    });
  });

  group('RecentActivityList Widget Tests', () {
    testWidgets('should show empty state', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            dashboardActivityProvider.overrideWith((ref) => Future.value([])),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: RecentActivityList(),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Recent Activity'), findsOneWidget);
      expect(find.text('No activity yet'), findsOneWidget);
      expect(find.textContaining('crop scan'), findsOneWidget);
      expect(find.byIcon(Icons.history_toggle_off_rounded), findsOneWidget);
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
