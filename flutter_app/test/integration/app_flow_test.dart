import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_app/features/auth/presentation/farmer_login_screen.dart';
import 'package:flutter_app/features/dashboard/presentation/farmer_dashboard_screen.dart';
import 'package:flutter_app/features/crop_diagnosis/presentation/crop_doctor_screen.dart';
import 'package:go_router/go_router.dart';

/// Integration Tests for Complete User Flows
/// 
/// Tests end-to-end user journeys through the application.
/// Uses GoRouter in test harness to support specific screen transitions.
void main() {
  group('Authentication Flow Tests', () {
    testWidgets('complete login flow should work', (tester) async {
       final router = GoRouter(
        initialLocation: '/login',
        routes: [
          GoRoute(
            path: '/login',
            builder: (context, state) => const FarmerLoginScreen(),
          ),
          GoRoute(
            path: '/dashboard',
            builder: (context, state) => const Scaffold(body: Text('Dashboard Screen')),
          ),
        ],
      );

      await tester.pumpWidget(
         ProviderScope(
          child: MaterialApp.router(
            routerConfig: router,
          ),
        ),
      );
      
      await tester.pumpAndSettle();

      // Should start at login screen
      expect(find.text('AgriPulse'), findsOneWidget);
      expect(find.text('Farmer Login'), findsOneWidget);

      // Enter phone number
      await tester.enterText(
        find.byKey(const Key('phone_input')),
        '+919876543210',
      );

      // Send OTP
      await tester.tap(find.byKey(const Key('send_otp_button')));
      await tester.pumpAndSettle();

      // Should show OTP input
      expect(find.text('Enter Verification Code'), findsOneWidget);

      // Enter OTP
      await tester.enterText(
        find.byKey(const Key('otp_input')),
        '123456',
      );

      // Verify & Login
      await tester.tap(find.byKey(const Key('verify_button')));
      await tester.pumpAndSettle();

      // Should show success message / Navigate to Dashboard
      expect(find.text('Dashboard Screen'), findsOneWidget);
    });

    testWidgets('should handle invalid phone number', (tester) async {
      final router = GoRouter(
        initialLocation: '/login',
        routes: [
          GoRoute(
            path: '/login',
            builder: (context, state) => const FarmerLoginScreen(),
          ),
        ],
      );

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp.router(
            routerConfig: router,
          ),
        ),
      );
      
      await tester.pumpAndSettle();

      // Enter invalid phone
      await tester.enterText(
        find.byKey(const Key('phone_input')),
        '123',
      );
      
      await tester.tap(find.byKey(const Key('send_otp_button')));
      await tester.pumpAndSettle();

      // Should show error
      expect(find.text('Invalid Phone Number'), findsOneWidget);
    });

    testWidgets('should handle incorrect OTP', (tester) async {
      final router = GoRouter(
        initialLocation: '/login',
        routes: [
          GoRoute(
            path: '/login',
            builder: (context, state) => const FarmerLoginScreen(),
          ),
        ],
      );

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp.router(
            routerConfig: router,
          ),
        ),
      );
      
      await tester.pumpAndSettle();

      // Login flow
      await tester.enterText(
        find.byKey(const Key('phone_input')),
        '+919876543210',
      );
      await tester.tap(find.byKey(const Key('send_otp_button')));
      await tester.pumpAndSettle();

      // Enter wrong OTP
      await tester.enterText(
        find.byKey(const Key('otp_input')),
        '000000',
      );
      await tester.tap(find.byKey(const Key('verify_button')));
      await tester.pumpAndSettle();

      // Should show error
      expect(find.textContaining('Invalid OTP'), findsOneWidget);
    });
  });

  group('Dashboard Screen Tests', () {
    testWidgets('dashboard should render all sections', (tester) async {
       final router = GoRouter(
        initialLocation: '/dashboard',
        routes: [
          GoRoute(
            path: '/dashboard',
            builder: (context, state) => const FarmerDashboardScreen(),
          ),
        ],
      );

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp.router(
            routerConfig: router,
          ),
        ),
      );
      
      await tester.pumpAndSettle();

      // Verify all main sections exist
      expect(find.text('AI Agri Tools'), findsOneWidget);
      expect(find.text('Recent Activity'), findsOneWidget);
      expect(find.text('Hassan, Karnataka'), findsOneWidget);
      
      // Verify action cards
      expect(find.text('Crop Doctor'), findsOneWidget);
      expect(find.text('Yield Predictor'), findsOneWidget);
      expect(find.text('Market Prices'), findsOneWidget);
    });
  });

  group('Crop Diagnosis Screen Tests', () {
    testWidgets('crop doctor screen should render picker', (tester) async {
      final router = GoRouter(
        initialLocation: '/doctor',
        routes: [
          GoRoute(
            path: '/doctor',
            builder: (context, state) => const CropDoctorScreen(),
          ),
        ],
      );

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp.router(
            routerConfig: router,
          ),
        ),
      );
      
      await tester.pumpAndSettle();

      // Verify picker UI
      expect(find.text('Upload Image'), findsOneWidget);
      expect(find.text('Camera'), findsOneWidget);
      expect(find.text('Gallery'), findsOneWidget);
    });
  });

  group('Screen Transitions', () {
    testWidgets('login to dashboard transition data flow', (tester) async {
      // This tests that the login state can be set and read
      final container = ProviderContainer();
      addTearDown(container.dispose);
      // Keep provider alive to prevent disposal during navigation in test
      container.listen(loginControllerProvider, (_, __) {});
      
      final router = GoRouter(
        initialLocation: '/login',
        routes: [
          GoRoute(
            path: '/login',
            builder: (context, state) => const FarmerLoginScreen(),
          ),
          GoRoute(
            path: '/dashboard',
            builder: (context, state) => const Scaffold(body: Text('Dashboard Screen')),
          ),
        ],
      );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp.router(
            routerConfig: router,
          ),
        ),
      );
      
      await tester.pumpAndSettle();

      // Perform login
      await tester.enterText(
        find.byKey(const Key('phone_input')),
        '+919876543210',
      );
      await tester.tap(find.byKey(const Key('send_otp_button')));
      await tester.pumpAndSettle();
      
      await tester.enterText(
        find.byKey(const Key('otp_input')),
        '123456',
      );
      await tester.tap(find.byKey(const Key('verify_button')));
      await tester.pumpAndSettle();

      // Success message should appear
      expect(find.text('Dashboard Screen'), findsOneWidget);
    });
  });
}
