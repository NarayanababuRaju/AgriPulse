import 'package:hive/hive.dart';

class DiagnosisRecord {
  final String id;
  final String imagePath;
  final String diseaseName;
  final double confidence;
  final String treatmentSummary;
  final DateTime timestamp;
  final String? farmerInput;
  final String? refinementReasoning;
  final String? treatmentAdjustment;

  DiagnosisRecord({
    required this.id,
    required this.imagePath,
    required this.diseaseName,
    required this.confidence,
    required this.treatmentSummary,
    required this.timestamp,
    this.farmerInput,
    this.refinementReasoning,
    this.treatmentAdjustment,
  });
}

class DiagnosisRecordAdapter extends TypeAdapter<DiagnosisRecord> {
  @override
  final int typeId = 0;

  @override
  DiagnosisRecord read(BinaryReader reader) {
    String id = reader.readString();
    String imagePath = reader.readString();
    String diseaseName = reader.readString();
    double confidence = reader.readDouble();
    String treatmentSummary = reader.readString();
    DateTime timestamp = DateTime.fromMillisecondsSinceEpoch(reader.readInt());
    
    String? farmerInput;
    String? refinementReasoning;
    String? treatmentAdjustment;

    // Check availability of optional fields via boolean flags if we wrote them that way.
    // BUT since we are appending to an existing structure that didn't have flags,
    // we must assume the structure is:
    // [Legacy Fields] + [Optional Fields]
    // If the box contains legacy data, the reader might be at the end.
    // However, Hive Reader doesn't expose `availableBytes`.
    
    // STRATEGY: 
    // Since this is a Hackathon and we are in dev, we will wrap the read of new fields
    // in a try-catch block. If readBool/readString fails (EOF), it means it's an old record.
    try {
        if (reader.readBool()) farmerInput = reader.readString();
        if (reader.readBool()) refinementReasoning = reader.readString();
        if (reader.readBool()) treatmentAdjustment = reader.readString();
    } catch (e) {
        // End of stream likely reached (Legacy Record)
    }

    return DiagnosisRecord(
      id: id,
      imagePath: imagePath,
      diseaseName: diseaseName,
      confidence: confidence,
      treatmentSummary: treatmentSummary,
      timestamp: timestamp,
      farmerInput: farmerInput,
      refinementReasoning: refinementReasoning,
      treatmentAdjustment: treatmentAdjustment,
    );
  }

  @override
  void write(BinaryWriter writer, DiagnosisRecord obj) {
    writer.writeString(obj.id);
    writer.writeString(obj.imagePath);
    writer.writeString(obj.diseaseName);
    writer.writeDouble(obj.confidence);
    writer.writeString(obj.treatmentSummary);
    writer.writeInt(obj.timestamp.millisecondsSinceEpoch);
    
    // Write optionals with presence flags
    writer.writeBool(obj.farmerInput != null);
    if (obj.farmerInput != null) writer.writeString(obj.farmerInput!);
    
    writer.writeBool(obj.refinementReasoning != null);
    if (obj.refinementReasoning != null) writer.writeString(obj.refinementReasoning!);
    
    writer.writeBool(obj.treatmentAdjustment != null);
    if (obj.treatmentAdjustment != null) writer.writeString(obj.treatmentAdjustment!);
  }
}

