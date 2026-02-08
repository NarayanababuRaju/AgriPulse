import 'dart:async';
import 'package:flutter_app/features/auth/domain/auth_repository.dart';
import 'package:flutter_app/features/auth/domain/entities/farmer.dart';
import 'package:flutter_app/core/services/local_vault.dart';

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
      const user = Farmer(
        id: "farmer_1",
        phoneNumber: "+919535054466", // Mock
        name: "Raju", // Mock Name
        language: "en", // Default to English
      );
      
      // Persist user
      await LocalVault().saveUser({
        'id': user.id,
        'phoneNumber': user.phoneNumber,
        'name': user.name,
        'language': user.language,
      });

      _currentUser = user;
      return user;
    } else {
      throw Exception("Invalid OTP");
    }
  }

  @override
  Future<void> logout() async {
    await Future.delayed(const Duration(milliseconds: 500));
    await LocalVault().clearUser();
    _currentUser = null;
  }

  @override
  Future<Farmer?> getCurrentUser() async {
    if (_currentUser != null) return _currentUser;
    
    final userData = LocalVault().getUser();
    if (userData != null) {
      _currentUser = Farmer(
        id: userData['id'],
        phoneNumber: userData['phoneNumber'],
        name: userData['name'],
        language: userData['language'],
      );
    }
    
    return _currentUser;
  }

  @override
  Future<Farmer> skipLogin() async {
    // Simulate short delay
    await Future.delayed(const Duration(milliseconds: 500));

    const user = Farmer(
      id: "demo_farmer",
      phoneNumber: "+911234567890",
      name: "Raju",
      language: "en",
    );

    // Persist demo user
    await LocalVault().saveUser({
      'id': user.id,
      'phoneNumber': user.phoneNumber,
      'name': user.name,
      'language': user.language,
    });

    _currentUser = user;
    return user;
  }
}
