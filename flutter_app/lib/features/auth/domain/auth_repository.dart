import 'package:flutter_app/features/auth/domain/entities/farmer.dart';

abstract class AuthRepository {
  /// Sends an OTP to the provided phone number.
  /// Returns a verification ID (simulated or real).
  Future<String> sendOtp(String phoneNumber);

  /// Verifies the OTP and logs the user in.
  /// Returns the authenticated [Farmer] entity.
  Future<Farmer> verifyOtp({
    required String verificationId,
    required String smsCode,
  });

  /// Logs out the current user.
  Future<void> logout();

  /// Gets the current user if already logged in.
  Future<Farmer?> getCurrentUser();
}
