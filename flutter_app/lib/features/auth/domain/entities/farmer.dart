class Farmer {
  final String id;
  final String phoneNumber;
  final String? name;
  final String? language;
  final List<String> roles;
  final bool onboardingComplete;
  final String? selectedFieldId;
  final int schemaVersion;

  const Farmer({
    required this.id,
    required this.phoneNumber,
    this.name,
    this.language = 'en',
    this.roles = const ['Farmer'],
    this.onboardingComplete = false,
    this.selectedFieldId,
    this.schemaVersion = 1,
  });

  Farmer copyWith({
    String? id,
    String? phoneNumber,
    String? name,
    String? language,
    List<String>? roles,
    bool? onboardingComplete,
    String? selectedFieldId,
    int? schemaVersion,
  }) {
    return Farmer(
      id: id ?? this.id,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      name: name ?? this.name,
      language: language ?? this.language,
      roles: roles ?? this.roles,
      onboardingComplete: onboardingComplete ?? this.onboardingComplete,
      selectedFieldId: selectedFieldId ?? this.selectedFieldId,
      schemaVersion: schemaVersion ?? this.schemaVersion,
    );
  }
}
