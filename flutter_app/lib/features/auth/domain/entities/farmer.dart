class Farmer {
  final String id;
  final String phoneNumber;
  final String? name;
  final String? language;

  const Farmer({
    required this.id,
    required this.phoneNumber,
    this.name,
    this.language = 'en',
  });
}
