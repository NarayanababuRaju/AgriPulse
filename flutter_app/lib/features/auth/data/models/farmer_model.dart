import 'package:flutter_app/features/auth/domain/entities/farmer.dart';

class FarmerModel extends Farmer {
  const FarmerModel({
    required String id,
    required String phoneNumber,
    String? name,
    String? language,
  }) : super(
          id: id,
          phoneNumber: phoneNumber,
          name: name,
          language: language,
        );

  factory FarmerModel.fromJson(Map<String, dynamic> json) {
    return FarmerModel(
      id: json['id'] as String,
      phoneNumber: json['phoneNumber'] as String,
      name: json['name'] as String?,
      language: json['language'] as String? ?? 'en',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'phoneNumber': phoneNumber,
      'name': name,
      'language': language,
    };
  }
}
