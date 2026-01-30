import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_app/features/auth/data/auth_repository_impl.dart';
import 'package:flutter_app/features/auth/domain/auth_repository.dart';
import 'package:flutter_app/features/auth/domain/entities/farmer.dart';

// ============================================================================
// 1. REPOSITORY PROVIDER
// ============================================================================
// This provider creates and manages the AuthRepository instance.
// Using the Provider interface allows us to easily swap implementations:
// - Current: AuthRepositoryImpl (mock OTP for rapid development)
// - Future: FirebaseAuthRepository (real Firebase Phone Auth)
// The repository abstraction keeps business logic separate from implementation details.
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepositoryImpl();
});

// ============================================================================
// 2. GLOBAL AUTHENTICATION STATE
// ============================================================================
// This StateNotifier manages the app-wide authentication state.
// It answers the question: "Who is currently logged in?"
// 
// AsyncValue<Farmer?> provides three states:
// - AsyncValue.loading(): Checking authentication status
// - AsyncValue.data(Farmer): User is authenticated
// - AsyncValue.data(null): User is not authenticated
// - AsyncValue.error(): Authentication check failed
class AuthStateNotifier extends StateNotifier<AsyncValue<Farmer?>> {
  final AuthRepository _repository;

  // Initialize with loading state and check for existing session
  AuthStateNotifier(this._repository) : super(const AsyncValue.loading()) {
    _init();
  }

  /// Check if user is already logged in (e.g., from previous session)
  Future<void> _init() async {
    try {
      final user = await _repository.getCurrentUser();
      state = AsyncValue.data(user);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  /// Update global state when user successfully logs in
  Future<void> login(Farmer user) async {
    state = AsyncValue.data(user);
  }

  /// Clear authentication state and call repository logout
  Future<void> logout() async {
    state = const AsyncValue.loading();
    await _repository.logout();
    state = const AsyncValue.data(null);
  }
}

final authStateProvider = StateNotifierProvider<AuthStateNotifier, AsyncValue<Farmer?>>((ref) {
  return AuthStateNotifier(ref.watch(authRepositoryProvider));
});


// ============================================================================
// 3. LOGIN FLOW CONTROLLER
// ============================================================================
// This controller manages the specific login flow state machine.
// It's separate from AuthStateNotifier because it handles transient UI states
// that are only relevant during the login process.
//
// State Machine Flow:
// initial → authenticating → otpSent → authenticating → authenticated
//                ↓                           ↓
//              error                       error
enum LoginStatus { initial, otpSent, authenticating, authenticated, error }

class LoginState {
  final LoginStatus status;
  final String? verificationId;
  final String? errorMessage;

  const LoginState({
    this.status = LoginStatus.initial,
    this.verificationId,
    this.errorMessage,
  });

  LoginState copyWith({
    LoginStatus? status,
    String? verificationId,
    String? errorMessage,
  }) {
    return LoginState(
      status: status ?? this.status,
      verificationId: verificationId ?? this.verificationId,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

class LoginController extends StateNotifier<LoginState> {
  final AuthRepository _repository;
  final AuthStateNotifier _authStateNotifier;

  LoginController(this._repository, this._authStateNotifier) : super(const LoginState());

  /// Step 1: Send OTP to the provided phone number
  /// Validates phone number format and triggers OTP delivery
  Future<void> sendOtp(String phoneNumber) async {
    // Basic validation: phone number should be at least 10 digits
    if (phoneNumber.length < 10) {
      state = state.copyWith(errorMessage: "Invalid Phone Number", status: LoginStatus.error);
      return;
    }

    // Show loading state while sending OTP
    state = state.copyWith(status: LoginStatus.authenticating, errorMessage: null);

    try {
      // Call repository to send OTP (mock or real Firebase)
      final vId = await _repository.sendOtp(phoneNumber);
      
      // Store verification ID for later OTP verification
      state = state.copyWith(
        status: LoginStatus.otpSent,
        verificationId: vId,
      );
    } catch (e) {
      state = state.copyWith(
        status: LoginStatus.error,
        errorMessage: e.toString(),
      );
    }
  }

  /// Step 2: Verify the OTP code entered by the user
  /// On success, updates both login flow state AND global auth state
  Future<void> verifyOtp(String smsCode) async {
    // Safety check: ensure we have a verification ID from sendOtp()
    if (state.verificationId == null) return;

    state = state.copyWith(status: LoginStatus.authenticating, errorMessage: null);

    try {
      // Verify OTP with the repository
      final user = await _repository.verifyOtp(
        verificationId: state.verificationId!,
        smsCode: smsCode,
      );
      
      // CRITICAL: Update the global auth state so the entire app knows user is logged in
      // This triggers navigation to dashboard and updates all auth-dependent widgets
      await _authStateNotifier.login(user);
      
      // Update local login flow state to show success
      state = state.copyWith(status: LoginStatus.authenticated);
      
    } catch (e) {
      // Show user-friendly error message
      // NOTE: "123456" is the magic OTP for mock authentication
      state = state.copyWith(
        status: LoginStatus.error,
        errorMessage: "Invalid OTP. Try 123456",
      );
    }
  }
  
  void reset() {
    state = const LoginState();
  }
}

// Provider for the LoginController
// autoDispose: Automatically cleans up when the login screen is disposed
// This prevents memory leaks and resets state when user navigates away
final loginControllerProvider = StateNotifierProvider.autoDispose<LoginController, LoginState>((ref) {
  final repo = ref.watch(authRepositoryProvider);
  final authNotifier = ref.read(authStateProvider.notifier);
  return LoginController(repo, authNotifier);
});
