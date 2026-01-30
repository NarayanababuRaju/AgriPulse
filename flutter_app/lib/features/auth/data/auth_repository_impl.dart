import 'dart:async';
import 'package:flutter_app/features/auth/domain/auth_repository.dart';
import 'package:flutter_app/features/auth/domain/entities/farmer.dart';

class AuthRepositoryImpl implements AuthRepository {
  // Mock storage for signed-in user
  Farmer? _currentUser;

  @override
  Future<String> sendOtp(String phoneNumber) async {
    // Simulate network delay
    await Future.delayed(const Duration(seconds: 1));
    
    // In a real app, this triggers Firebase Phone Auth
    // Here we just return a mock verification ID
    return "mock-verification-id-${DateTime.now().millisecondsSinceEpoch}";
  }

  @override
  Future<Farmer> verifyOtp({
    required String verificationId,
    required String smsCode,
  }) async {
    // Simulate network delay
    await Future.delayed(const Duration(seconds: 1));

    // Simple mock validation: "123456" is the magic code
    if (smsCode == "123456") {
      _currentUser = const Farmer(
        id: "farmer_1",
        phoneNumber: "+919535054466", // Mock
        name: "Raju", // Mock Name
        language: "ta", // Default to Tamil
      );
      return _currentUser!;
    } else {
      throw Exception("Invalid OTP");
    }
  }

  @override
  Future<void> logout() async {
    await Future.delayed(const Duration(milliseconds: 500));
    _currentUser = null;
  }

  @override
  Future<Farmer?> getCurrentUser() async {
    return _currentUser;
  }
}
