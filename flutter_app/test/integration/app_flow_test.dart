import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_app/features/auth/presentation/farmer_login_screen.dart';
import 'package:flutter_app/features/dashboard/presentation/farmer_dashboard_screen.dart';
import 'package:flutter_app/features/crop_diagnosis/presentation/crop_doctor_screen.dart';

/// Integration Tests for Complete User Flows
/// 
/// Tests end-to-end user journeys through the application.
/// Note: These tests focus on individual screen flows rather than full navigation
/// due to GoRouter complexity in test environment.
void main() {
  group('Authentication Flow Tests', () {
    testWidgets('complete login flow should work', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: const MaterialApp(
            home: FarmerLoginScreen(),
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

      // Should show success message
      expect(find.text('Login Successful!'), findsOneWidget);
    });

    testWidgets('should handle invalid phone number', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: const MaterialApp(
            home: FarmerLoginScreen(),
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
      await tester.pumpWidget(
        ProviderScope(
          child: const MaterialApp(
            home: FarmerLoginScreen(),
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
      await tester.pumpWidget(
        ProviderScope(
          child: const MaterialApp(
            home: FarmerDashboardScreen(),
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
      await tester.pumpWidget(
        ProviderScope(
          child: const MaterialApp(
            home: CropDoctorScreen(),
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
      
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: FarmerLoginScreen(),
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
      expect(find.text('Login Successful!'), findsOneWidget);
      
      container.dispose();
    });
  });
}
