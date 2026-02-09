import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter_app/core/services/local_vault.dart';
import 'package:mockito/mockito.dart';
import 'package:flutter_app/core/api/agri_pulse_service.dart';
import 'package:flutter_app/features/auth/domain/entities/farmer.dart';
import 'package:flutter_app/features/auth/presentation/farmer_login_screen.dart';
import 'package:flutter_app/features/auth/providers/auth_provider.dart';
import 'package:flutter_app/features/dashboard/presentation/providers/weather_provider.dart';
import 'package:flutter_app/features/profile/domain/entities/field.dart';
import 'package:flutter_app/features/dashboard/presentation/providers/activity_provider.dart';
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

  group('FarmerLoginScreen Widget Tests', () {
    testWidgets('should display AgriPulse branding', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            agriPulseServiceProvider.overrideWithValue(mockApiService),
          ],
          child: const MaterialApp(
            home: FarmerLoginScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.text('AgriPulse'), findsOneWidget);
      expect(find.text('Your Intelligent Farming Companion'), findsOneWidget);
      expect(find.byIcon(Icons.agriculture_rounded), findsOneWidget);
    });

    testWidgets('should show phone input initially', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            agriPulseServiceProvider.overrideWithValue(mockApiService),
          ],
          child: const MaterialApp(
            home: FarmerLoginScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Farmer Login'), findsOneWidget);
      expect(find.byKey(const Key('phone_input')), findsOneWidget);
      expect(find.byKey(const Key('send_otp_button')), findsOneWidget);
    });

    testWidgets('should show OTP input after sending OTP', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            agriPulseServiceProvider.overrideWithValue(mockApiService),
          ],
          child: const MaterialApp(
            home: FarmerLoginScreen(),
          ),
        ),
      );

      // Enter phone number
      await tester.enterText(
        find.byKey(const Key('phone_input')),
        '+919876543210',
      );
      
      // Tap Send OTP
      await tester.tap(find.byKey(const Key('send_otp_button')));
      await tester.pumpAndSettle();

      // Should now show OTP input
      expect(find.text('Enter Verification Code'), findsOneWidget);
      expect(find.byKey(const Key('otp_input')), findsOneWidget);
      expect(find.byKey(const Key('verify_button')), findsOneWidget);
      expect(find.byKey(const Key('change_number_button')), findsOneWidget);
    });

    testWidgets('should show error for invalid phone number', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            agriPulseServiceProvider.overrideWithValue(mockApiService),
          ],
          child: const MaterialApp(
            home: FarmerLoginScreen(),
          ),
        ),
      );

      // Enter invalid phone
      await tester.enterText(
        find.byKey(const Key('phone_input')),
        '123',
      );
      
      await tester.tap(find.byKey(const Key('send_otp_button')));
      await tester.pumpAndSettle();

      // Should show error snackbar
      expect(find.textContaining('Invalid Phone'), findsOneWidget);
    });

    testWidgets('Change Number button should reset flow', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            agriPulseServiceProvider.overrideWithValue(mockApiService),
          ],
          child: const MaterialApp(
            home: FarmerLoginScreen(),
          ),
        ),
      );

      // Send OTP
      await tester.enterText(
        find.byKey(const Key('phone_input')),
        '+919876543210',
      );
      await tester.tap(find.byKey(const Key('send_otp_button')));
      await tester.pumpAndSettle();

      // Tap Change Number
      await tester.tap(find.byKey(const Key('change_number_button')));
      await tester.pumpAndSettle();

      // Should be back to phone input
      expect(find.text('Farmer Login'), findsOneWidget);
      expect(find.byKey(const Key('send_otp_button')), findsOneWidget);
    });

    testWidgets('should verify OTP and show success', (tester) async {
       final router = GoRouter(
        initialLocation: '/login',
        routes: [
          GoRoute(
            path: '/login',
            builder: (context, state) => const FarmerLoginScreen(),
          ),
          GoRoute(
            path: '/',
            builder: (context, state) => const Scaffold(body: Text('Dashboard')),
          ),
        ],
        redirect: (context, state) {
          final container = ProviderScope.containerOf(context);
          final loggedIn = container.read(authStateProvider).value != null;
          if (loggedIn && state.matchedLocation == '/login') return '/';
          return null;
        },
      );

      // Seed vault with a field to avoid onboarding redirect in real scenarios 
      // (though our test GoRouter is simple, good practice)
      await LocalVault().saveFields('1', [
        const Field(id: 'field_1', name: 'Demo Plot', soilType: 'Red', acreage: 2.0, irrigationType: 'Drip')
      ]);

      final mockAuthRepository = MockAuthRepository();
      when(mockAuthRepository.sendOtp(any)).thenAnswer((_) async => 'verification_id');
      when(mockAuthRepository.verifyOtp(
        verificationId: anyNamed('verificationId'), 
        smsCode: anyNamed('smsCode'),
      )).thenAnswer((_) async => 
        const Farmer(id: '1', phoneNumber: '+919876543210'));
      
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authRepositoryProvider.overrideWithValue(mockAuthRepository),
            agriPulseServiceProvider.overrideWithValue(mockApiService),
            weatherProvider.overrideWith((ref) => WeatherNotifierMock(mockApiService)),
            dashboardActivityProvider.overrideWith((ref) => Future.value([])),
          ],
          child: MaterialApp.router(
            routerConfig: router,
          ),
        ),
      );

      // Send OTP
      await tester.enterText(
        find.byKey(const Key('phone_input')),
        '+919876543210',
      );
      await tester.tap(find.byKey(const Key('send_otp_button')));
      await tester.pump(const Duration(seconds: 1));
      await tester.pumpAndSettle();

      // Enter correct OTP
      await tester.enterText(
        find.byKey(const Key('otp_input')),
        '123456',
      );
      
      await tester.tap(find.byKey(const Key('verify_button')));
      await tester.pump(const Duration(seconds: 1));
      await tester.pumpAndSettle();

      expect(find.text('Dashboard'), findsOneWidget);
    });

    testWidgets('should skip login for demo', (tester) async {
       final router = GoRouter(
        initialLocation: '/login',
        routes: [
          GoRoute(
            path: '/login',
            builder: (context, state) => const FarmerLoginScreen(),
          ),
          GoRoute(
            path: '/',
            builder: (context, state) => const Scaffold(body: Text('Dashboard')),
          ),
        ],
        redirect: (context, state) {
          final container = ProviderScope.containerOf(context);
          final loggedIn = container.read(authStateProvider).value != null;
          if (loggedIn && state.matchedLocation == '/login') return '/';
          return null;
        },
      );

      final mockAuthRepository = MockAuthRepository();
      when(mockAuthRepository.getCurrentUser()).thenAnswer((_) async => null);
      when(mockAuthRepository.skipLogin()).thenAnswer((_) async => 
        const Farmer(id: '99', phoneNumber: '+0000000000'));
      
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authRepositoryProvider.overrideWithValue(mockAuthRepository),
            agriPulseServiceProvider.overrideWithValue(mockApiService),
            weatherProvider.overrideWith((ref) => WeatherNotifierMock(mockApiService)),
            dashboardActivityProvider.overrideWith((ref) => Future.value([])),
          ],
          child: MaterialApp.router(
            routerConfig: router,
          ),
        ),
      );

      // Verify branding and skip button presence
      expect(find.text('AgriPulse'), findsOneWidget);
      expect(find.byKey(const Key('skip_login_button')), findsOneWidget);

      // Tap Skip Login
      await tester.tap(find.byKey(const Key('skip_login_button')));
      await tester.pump(); // Start navigation/state change
      await tester.pump(const Duration(seconds: 1)); // Wait for async login
      await tester.pumpAndSettle(); // Settle animations/redirects

      // Should be on dashboard
      expect(find.text('Dashboard'), findsOneWidget);
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
