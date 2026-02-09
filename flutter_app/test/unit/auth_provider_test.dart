import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_app/features/auth/providers/auth_provider.dart';
import 'package:flutter_app/features/auth/domain/entities/farmer.dart';
import 'package:flutter_app/features/auth/domain/auth_repository.dart';
import 'package:flutter_app/core/api/agri_pulse_service.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';

@GenerateNiceMocks([
  MockSpec<AuthRepository>(),
  MockSpec<AgriPulseService>(),
])
import 'auth_provider_test.mocks.dart';

/// Unit Tests for Authentication Providers
void main() {
  group('LoginController Tests', () {
    late ProviderContainer container;
    late MockAuthRepository mockRepo;

    setUp(() {
      mockRepo = MockAuthRepository();
      container = ProviderContainer(
        overrides: [
          authRepositoryProvider.overrideWith((ref) => mockRepo),
        ],
      );
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
      when(mockRepo.sendOtp(any)).thenAnswer((_) async => 'mock_v_id');
      
      await controller.sendOtp('+919876543210');
      
      final state = container.read(loginControllerProvider);
      expect(state.status, LoginStatus.otpSent);
      expect(state.verificationId, 'mock_v_id');
    });

    test('verifyOtp with correct OTP should authenticate', () async {
      final controller = container.read(loginControllerProvider.notifier);
      const testFarmer = Farmer(id: '123', phoneNumber: '+919876543210');
      
      when(mockRepo.sendOtp(any)).thenAnswer((_) async => 'mock_v_id');
      when(mockRepo.verifyOtp(verificationId: anyNamed('verificationId'), smsCode: anyNamed('smsCode')))
          .thenAnswer((_) async => testFarmer);
      
      await controller.sendOtp('+919876543210');
      await controller.verifyOtp('123456');
      
      final state = container.read(loginControllerProvider);
      expect(state.status, LoginStatus.authenticated);
      
      final authState = container.read(authStateProvider);
      expect(authState.value, testFarmer);
    });
  });

  group('AuthStateNotifier Tests', () {
    late ProviderContainer container;
    late MockAuthRepository mockRepo;

    setUp(() {
      mockRepo = MockAuthRepository();
      // Ensure getCurrentUser returns null initially for consistent tests
      when(mockRepo.getCurrentUser()).thenAnswer((_) async => null);
      
      container = ProviderContainer(
        overrides: [
          authRepositoryProvider.overrideWith((ref) => mockRepo),
        ],
      );
    });

    tearDown(() {
      container.dispose();
    });

    test('initial state should be loading then data(null)', () async {
      final authState = container.read(authStateProvider);
      expect(authState, isA<AsyncLoading>());
      
      await Future.delayed(Duration.zero);
      final finalState = container.read(authStateProvider);
      expect(finalState.value, isNull);
    });

    test('login should update state with farmer', () async {
      await Future.delayed(Duration.zero);
      final notifier = container.read(authStateProvider.notifier);
      await Future.delayed(Duration.zero); // Let _init finish
      await Future.delayed(Duration.zero); // Wait for _init to finish
      
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
      await Future.delayed(Duration.zero);
      final notifier = container.read(authStateProvider.notifier);
      const testFarmer = Farmer(
        id: 'test_123',
        phoneNumber: '+919876543210',
      );
      
      await notifier.login(testFarmer);
      
      // Stub logout
      when(mockRepo.logout()).thenAnswer((_) async => {});
      
      await notifier.logout();
      
      final state = container.read(authStateProvider);
      expect(state.value, isNull);
      verify(mockRepo.logout()).called(1);
    });
  });
}
