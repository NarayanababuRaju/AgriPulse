import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_app/features/auth/presentation/farmer_login_screen.dart';

/// Widget Tests for Farmer Login Screen
/// 
/// Tests the UI rendering and user interactions for the authentication flow.
void main() {
  group('FarmerLoginScreen Widget Tests', () {
    testWidgets('should display AgriPulse branding', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: const FarmerLoginScreen(),
          ),
        ),
      );

      expect(find.text('AgriPulse'), findsOneWidget);
      expect(find.text('Your Intelligent Farming Companion'), findsOneWidget);
      expect(find.byIcon(Icons.agriculture_rounded), findsOneWidget);
    });

    testWidgets('should show phone input initially', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: const FarmerLoginScreen(),
          ),
        ),
      );

      expect(find.text('Farmer Login'), findsOneWidget);
      expect(find.byKey(const Key('phone_input')), findsOneWidget);
      expect(find.byKey(const Key('send_otp_button')), findsOneWidget);
    });

    testWidgets('should show OTP input after sending OTP', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: const FarmerLoginScreen(),
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
          child: MaterialApp(
            home: const FarmerLoginScreen(),
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
      expect(find.text('Invalid Phone Number'), findsOneWidget);
    });

    testWidgets('Change Number button should reset flow', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: const FarmerLoginScreen(),
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
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: const FarmerLoginScreen(),
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

      // Enter correct OTP
      await tester.enterText(
        find.byKey(const Key('otp_input')),
        '123456',
      );
      
      await tester.tap(find.byKey(const Key('verify_button')));
      await tester.pumpAndSettle();

      // Should show success message (navigation happens via listener)
      expect(find.text('Login Successful!'), findsOneWidget);
    });
  });
}
