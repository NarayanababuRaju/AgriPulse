import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'package:mockito/mockito.dart';
import 'package:flutter_app/core/services/local_vault.dart';
import 'package:flutter_app/core/api/agri_pulse_service.dart';
import 'package:flutter_app/features/auth/presentation/farmer_login_screen.dart';
import 'package:flutter_app/features/dashboard/presentation/farmer_dashboard_screen.dart';
import 'package:flutter_app/features/crop_diagnosis/presentation/crop_doctor_screen.dart';
import 'package:flutter_app/features/yield_prediction/presentation/screens/yield_prediction_screen.dart';
import 'package:flutter_app/features/auth/providers/auth_provider.dart';

import 'package:flutter_app/features/dashboard/presentation/providers/activity_provider.dart';
import 'package:flutter_app/features/dashboard/presentation/providers/weather_provider.dart';
import 'package:flutter_app/features/auth/domain/entities/farmer.dart';
import 'package:flutter_app/features/profile/domain/entities/field.dart';
import '../unit/auth_provider_test.mocks.dart';

/// Integration Tests for Complete User Flows
/// 
/// Tests end-to-end user journeys through the application.
/// Uses GoRouter in test harness to support specific screen transitions.
void main() {
  late Directory tempDir;

  late MockAgriPulseService mockApiService;

  setUp(() async {
    final binding = TestWidgetsFlutterBinding.ensureInitialized();
    binding.platformDispatcher.implicitView!.physicalSize = const Size(1920, 1080);
    binding.platformDispatcher.implicitView!.devicePixelRatio = 1.0;
    
    mockApiService = MockAgriPulseService();
    // Stub for MiniForecastWidget and other weather-dependent components
    when(mockApiService.getForecast(11.2189, 78.1674)).thenAnswer((_) async => {
      'daily_summary': List.generate(7, (i) => {
        'time': '2026-02-1$i',
        'condition': 'Sunny',
        'temp': 28.0 + i,
      })
    });

    tempDir = Directory.systemTemp.createTempSync();
    Hive.init(tempDir.path);
    await LocalVault().init();

    // Default Seed for all integration tests
    await LocalVault().saveFields('1', [
      const Field(id: 'field_1', name: 'Demo Plot', soilType: 'Red', acreage: 2.0, irrigationType: 'Drip')
    ]);
    await LocalVault().saveSelectedFieldId('1', 'field_1');
  });

  tearDown(() {
    final binding = TestWidgetsFlutterBinding.ensureInitialized();
    binding.platformDispatcher.implicitView!.resetPhysicalSize();
    binding.platformDispatcher.implicitView!.resetDevicePixelRatio();
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  Widget createTestWidget({required GoRouter router, List<Override> overrides = const []}) {
    return ProviderScope(
      overrides: [
        agriPulseServiceProvider.overrideWithValue(mockApiService),
        weatherProvider.overrideWith((ref) => WeatherNotifierMock(mockApiService)),
        dashboardActivityProvider.overrideWith((ref) => Future.value([])),
        ...overrides,
      ],
      child: MaterialApp.router(
        routerConfig: router,
      ),
    );
  }

  group('Authentication Flow Tests', () {
    testWidgets('complete login flow should work', (tester) async {
       final mockAuthRepository = MockAuthRepository();
       when(mockAuthRepository.sendOtp(any)).thenAnswer((_) async => 'verification_id');
       when(mockAuthRepository.verifyOtp(
         verificationId: anyNamed('verificationId'), 
         smsCode: anyNamed('smsCode'),
       )).thenAnswer((_) async => 
         const Farmer(id: '1', phoneNumber: '+919876543210'));

       final router = GoRouter(
        initialLocation: '/login',
        routes: [
          GoRoute(path: '/login', builder: (context, state) => const FarmerLoginScreen()),
          GoRoute(path: '/dashboard', builder: (context, state) => const Scaffold(body: Text('Dashboard Screen'))),
        ],
        redirect: (context, state) {
          final loggedIn = ProviderScope.containerOf(context).read(authStateProvider).value != null;
          if (loggedIn && (state.matchedLocation == '/login' || state.matchedLocation == '/')) return '/dashboard';
          return null;
        },
      );

      await tester.pumpWidget(
        createTestWidget(
          router: router,
          overrides: [
            authRepositoryProvider.overrideWithValue(mockAuthRepository),
          ],
        ),
      );
      
      await tester.pumpAndSettle();

      // Should start at login screen
      expect(find.text('AgriPulse'), findsOneWidget);
      expect(find.text('Farmer Login'), findsOneWidget);

      // Enter phone number
      await tester.enterText(find.byKey(const Key('phone_input')), '+919876543210');
      await tester.tap(find.byKey(const Key('send_otp_button')));
      await tester.pump(const Duration(seconds: 1));
      await tester.pumpAndSettle();

      // Should show OTP input
      expect(find.text('Enter Verification Code'), findsOneWidget);

      await tester.enterText(find.byKey(const Key('otp_input')), '123456');
      await tester.tap(find.byKey(const Key('verify_button')));
      // Should be dashboard
      await tester.pump(const Duration(seconds: 1));
      await tester.pumpAndSettle();
      expect(find.text('Dashboard Screen'), findsOneWidget);
    });

    testWidgets('should handle invalid phone number', (tester) async {
      final mockAuthRepository = MockAuthRepository();
      final router = GoRouter(
        initialLocation: '/login',
        routes: [
          GoRoute(path: '/login', builder: (context, state) => const FarmerLoginScreen()),
        ],
      );

      await tester.pumpWidget(
        createTestWidget(
          router: router,
          overrides: [authRepositoryProvider.overrideWithValue(mockAuthRepository)],
        ),
      );
      
      await tester.pumpAndSettle();

      await tester.enterText(find.byKey(const Key('phone_input')), '123');
      await tester.tap(find.byKey(const Key('send_otp_button')));
      await tester.pumpAndSettle();
      expect(find.text('Invalid Phone Number'), findsOneWidget);
    });
  });

  group('Dashboard Screen Tests', () {
    testWidgets('dashboard should render all sections', (tester) async {
       final router = GoRouter(
        initialLocation: '/',
        routes: [
          GoRoute(path: '/', builder: (context, state) => const FarmerDashboardScreen()),
        ],
      );

      await tester.pumpWidget(createTestWidget(router: router));
      await tester.pump(const Duration(seconds: 1));

      expect(find.text('Smart Tools'), findsOneWidget);
      expect(find.text('Recent Activity'), findsOneWidget);
      expect(find.text('Namakkal, Tamil Nadu'), findsOneWidget);
    });
  });

  group('Crop Diagnosis Screen Tests', () {
    testWidgets('crop doctor screen should render picker', (tester) async {
      final router = GoRouter(
        initialLocation: '/doctor',
        routes: [
          GoRoute(path: '/doctor', builder: (context, state) => const CropDoctorScreen()),
        ],
      );

      await tester.pumpWidget(createTestWidget(router: router));
      await tester.pump(const Duration(seconds: 1));

      expect(find.text('Upload Image'), findsOneWidget);
      expect(find.text('Camera'), findsOneWidget);
      expect(find.text('Gallery'), findsOneWidget);
    });
  });

  group('Yield Prediction Screen Tests', () {
    testWidgets('yield prediction screen should render inputs', (tester) async {
      final router = GoRouter(
        initialLocation: '/yield',
        routes: [
          GoRoute(path: '/yield', builder: (context, state) => const YieldPredictionScreen()),
        ],
      );

      await tester.pumpWidget(createTestWidget(router: router));
      // Wait for animations and layout
      await tester.pump(const Duration(seconds: 1));
      await tester.pump(const Duration(milliseconds: 500)); // Additional pump for state

      expect(find.text('FIELD PARAMETERS'), findsOneWidget);
      expect(find.text('Run Prediction'), findsOneWidget);
    });
  });

  group('Screen Transitions', () {
    testWidgets('login to dashboard transition data flow', (tester) async {
      final mockAuthRepository = MockAuthRepository();
      when(mockAuthRepository.sendOtp(any)).thenAnswer((_) async => 'verification_id');
      when(mockAuthRepository.verifyOtp(
        verificationId: anyNamed('verificationId'), 
        smsCode: anyNamed('smsCode'),
      )).thenAnswer((_) async => 
        const Farmer(id: '1', phoneNumber: '+919876543210'));
      
      final container = ProviderContainer(
        overrides: [
          agriPulseServiceProvider.overrideWithValue(mockApiService),
          authRepositoryProvider.overrideWithValue(mockAuthRepository),
          weatherProvider.overrideWith((ref) => WeatherNotifierMock(mockApiService)),
          dashboardActivityProvider.overrideWith((ref) => Future.value([])),
        ],
      );
      addTearDown(container.dispose);
      
      final router = GoRouter(
        initialLocation: '/login',
        routes: [
          GoRoute(path: '/login', builder: (context, state) => const FarmerLoginScreen()),
          GoRoute(path: '/dashboard', builder: (context, state) => const Scaffold(body: Text('Dashboard Screen'))),
        ],
        redirect: (context, state) {
          final loggedIn = container.read(authStateProvider).value != null;
          if (loggedIn && (state.matchedLocation == '/login' || state.matchedLocation == '/')) return '/dashboard';
          return null;
        },
      );

      container.listen(authStateProvider, (prev, next) => router.refresh());

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp.router(routerConfig: router),
        ),
      );
      
      await tester.pumpAndSettle();

      await tester.enterText(find.byKey(const Key('phone_input')), '+919876543210');
      await tester.tap(find.byKey(const Key('send_otp_button')));
      await tester.pump(const Duration(seconds: 1));
      await tester.pumpAndSettle();
      
      await tester.enterText(find.byKey(const Key('otp_input')), '123456');
      await tester.tap(find.byKey(const Key('verify_button')));
      await tester.pump(const Duration(seconds: 1));
      await tester.pumpAndSettle();

      expect(find.text('Dashboard Screen'), findsOneWidget);
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
  Future<void> fetchWeather({Coordinates coords = defaultLocation}) async {
    // MiniForecastWidget calls getForecast directly from service,
    // but the notifier might also call it.
  }
}
