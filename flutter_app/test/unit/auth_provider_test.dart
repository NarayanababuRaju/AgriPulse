import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_app/features/auth/providers/auth_provider.dart';
import 'package:flutter_app/features/auth/domain/entities/farmer.dart';

/// Unit Tests for Authentication Providers
/// 
/// Tests the LoginController state machine and AuthStateNotifier behavior.
void main() {
  group('LoginController Tests', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer();
      // Keep the provider alive by adding a listener
      container.listen(loginControllerProvider, (_, __) {});
    });

    tearDown(() {
      container.dispose();
    });

    test('initial state should be LoginStatus.initial', () {
      final loginState = container.read(loginControllerProvider);
      
      expect(loginState.status, LoginStatus.initial);
      expect(loginState.verificationId, isNull);
      expect(loginState.errorMessage, isNull);
    });

    test('sendOtp with invalid phone number should set error', () async {
      final controller = container.read(loginControllerProvider.notifier);
      
      await controller.sendOtp('123'); // Too short
      
      final state = container.read(loginControllerProvider);
      expect(state.status, LoginStatus.error);
      expect(state.errorMessage, 'Invalid Phone Number');
    });

    test('sendOtp with valid phone number should update to otpSent', () async {
      final controller = container.read(loginControllerProvider.notifier);
      
      await controller.sendOtp('+919876543210');
      
      final state = container.read(loginControllerProvider);
      expect(state.status, LoginStatus.otpSent);
      expect(state.verificationId, isNotNull);
    });

    test('verifyOtp with correct OTP (123456) should authenticate', () async {
      final controller = container.read(loginControllerProvider.notifier);
      
      // First send OTP
      await controller.sendOtp('+919876543210');
      
      // Then verify with magic OTP
      await controller.verifyOtp('123456');
      
      final state = container.read(loginControllerProvider);
      expect(state.status, LoginStatus.authenticated);
    });

    test('verifyOtp with incorrect OTP should set error', () async {
      final controller = container.read(loginControllerProvider.notifier);
      
      await controller.sendOtp('+919876543210');
      await controller.verifyOtp('000000'); // Wrong OTP
      
      final state = container.read(loginControllerProvider);
      expect(state.status, LoginStatus.error);
      expect(state.errorMessage, contains('Invalid OTP'));
    });

    test('reset should return to initial state', () async {
      final controller = container.read(loginControllerProvider.notifier);
      
      await controller.sendOtp('+919876543210');
      controller.reset();
      
      final state = container.read(loginControllerProvider);
      expect(state.status, LoginStatus.initial);
      expect(state.verificationId, isNull);
    });
  });

  group('AuthStateNotifier Tests', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
    });

    test('initial state should be loading', () {
      final authState = container.read(authStateProvider);
      
      // Initially loading while checking repo
      expect(authState, isA<AsyncLoading>());
    });

    test('login should update state with farmer', () async {
      // Allow _init() to complete its microtask/Future and set initial null state
      // Increased delay to ensure robustness against microtask scheduling
      await Future.delayed(const Duration(milliseconds: 200));
      
      final notifier = container.read(authStateProvider.notifier);
      const testFarmer = Farmer(
        id: 'test_123',
        phoneNumber: '+919876543210',
        name: 'Test Farmer',
      );
      
      await notifier.login(testFarmer);
      
      final state = container.read(authStateProvider);
      expect(state.value, equals(testFarmer));
    });

    test('logout should clear farmer data', () async {
      final notifier = container.read(authStateProvider.notifier);
      const testFarmer = Farmer(
        id: 'test_123',
        phoneNumber: '+919876543210',
      );
      
      await notifier.login(testFarmer);
      await notifier.logout();
      
      final state = container.read(authStateProvider);
      expect(state.value, isNull);
    });
  });
}
