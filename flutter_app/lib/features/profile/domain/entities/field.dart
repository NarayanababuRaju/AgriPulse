class Field {
  final String id;
  final String name;
  final String soilType;
  final double acreage;
  final String? irrigationType;
  final String? cropType;
  final Map<String, double>? coordinates;

  const Field({
    required this.id,
    required this.name,
    required this.soilType,
    required this.acreage,
    this.irrigationType,
    this.cropType,
    this.coordinates,
  });

  factory Field.fromJson(Map<String, dynamic> json) {
    return Field(
      id: json['id'],
      name: json['name'],
      soilType: json['soilType'],
      acreage: (json['acreage'] ?? 0.0).toDouble(),
      irrigationType: json['irrigationType'],
      cropType: json['cropType'] ?? 'onion', // Default to onion for now
      coordinates: (json['coordinates'] as Map?)?.cast<String, double>(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'soilType': soilType,
      'acreage': acreage,
      'irrigationType': irrigationType,
      'cropType': cropType,
      'coordinates': coordinates,
    };
  }
}

class CropCycle {
  final String id;
  final String fieldId;
  final String seasonName;
  final DateTime? startDate;
  final DateTime? expectedHarvestDate;
  final String status;

  const CropCycle({
    required this.id,
    required this.fieldId,
    required this.seasonName,
    this.startDate,
    this.expectedHarvestDate,
    this.status = 'active',
  });

  factory CropCycle.fromJson(Map<String, dynamic> json) {
    return CropCycle(
      id: json['id'],
      fieldId: json['fieldId'],
      seasonName: json['seasonName'],
      startDate: json['startDate'] != null ? DateTime.parse(json['startDate']) : null,
      expectedHarvestDate: json['expectedHarvestDate'] != null ? DateTime.parse(json['expectedHarvestDate']) : null,
      status: json['status'] ?? 'active',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'fieldId': fieldId,
      'seasonName': seasonName,
      'startDate': startDate?.toIso8601String(),
      'expectedHarvestDate': expectedHarvestDate?.toIso8601String(),
      'status': status,
    };
  }
}
