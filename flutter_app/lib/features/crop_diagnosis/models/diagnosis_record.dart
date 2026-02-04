import 'package:hive/hive.dart';
import 'thread_item.dart';

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
  final String? severity; // High, Medium, Low
  final double? temperature;
  final double? humidity;
  final String? cropName;
  final String? languageCode;
  
  // Collaborative Workspace Context (Phase 20)
  final String? irrigationStage;
  final String? soilMoisture;
  final String? weatherEvent;
  final String? spreadPattern;
  final String? lastTreatment;
  final String? dosage;
  
  // Phase 24.1: Permanent Initial Markers (Bulletproof extraction)
  final String? initialUserInput;
  final String? initialAiResponse;
  
  // Phase 24: Recursive Thread
  final List<ThreadItem>? thread;

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
    this.severity,
    this.temperature,
    this.humidity,
    this.cropName,
    this.languageCode,
    this.irrigationStage,
    this.soilMoisture,
    this.weatherEvent,
    this.spreadPattern,
    this.lastTreatment,
    this.dosage,
    this.initialUserInput,
    this.initialAiResponse,
    this.thread,
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
    String? severity;
    double? temperature;
    double? humidity;
    String? cropName;
    String? languageCode;
    String? irrigationStage;
    String? soilMoisture;
    String? weatherEvent;
    String? spreadPattern;
    String? lastTreatment;
    String? dosage;
    String? initialUserInput;
    String? initialAiResponse;
    List<ThreadItem>? thread;

    // Check availability of optional fields via boolean flags
    try {
        if (reader.readBool()) farmerInput = reader.readString();
        if (reader.readBool()) refinementReasoning = reader.readString();
        if (reader.readBool()) treatmentAdjustment = reader.readString();
        if (reader.readBool()) severity = reader.readString();
        if (reader.readBool()) temperature = reader.readDouble();
        if (reader.readBool()) humidity = reader.readDouble();
        if (reader.readBool()) cropName = reader.readString();
        if (reader.readBool()) languageCode = reader.readString();
        
        // Phase 20 Fields
        if (reader.readBool()) irrigationStage = reader.readString();
        if (reader.readBool()) soilMoisture = reader.readString();
        if (reader.readBool()) weatherEvent = reader.readString();
        if (reader.readBool()) spreadPattern = reader.readString();
        if (reader.readBool()) lastTreatment = reader.readString();
        if (reader.readBool()) dosage = reader.readString();
        
        // Phase 24.1
        if (reader.readBool()) initialUserInput = reader.readString();
        if (reader.readBool()) initialAiResponse = reader.readString();
        
        // Phase 24
        if (reader.readBool()) {
           int count = reader.readInt();
           thread = [];
           for (var i=0; i < count; i++) {
             final item = reader.read();
             if (item is ThreadItem) {
               thread.add(item);
             } else if (item is Map) {
               // Handle legacy Map format
               thread.add(ThreadItem.fromMap(Map<String, dynamic>.from(item)));
             }
           }
        }
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
      severity: severity,
      temperature: temperature,
      humidity: humidity,
      cropName: cropName,
      languageCode: languageCode,
      irrigationStage: irrigationStage,
      soilMoisture: soilMoisture,
      weatherEvent: weatherEvent,
      spreadPattern: spreadPattern,
      lastTreatment: lastTreatment,
      dosage: dosage,
      initialUserInput: initialUserInput,
      initialAiResponse: initialAiResponse,
      thread: thread,
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

    writer.writeBool(obj.severity != null);
    if (obj.severity != null) writer.writeString(obj.severity!);

    writer.writeBool(obj.temperature != null);
    if (obj.temperature != null) writer.writeDouble(obj.temperature!);

    writer.writeBool(obj.humidity != null);
    if (obj.humidity != null) writer.writeDouble(obj.humidity!);
    
    writer.writeBool(obj.cropName != null);
    if (obj.cropName != null) writer.writeString(obj.cropName!);

    writer.writeBool(obj.languageCode != null);
    if (obj.languageCode != null) writer.writeString(obj.languageCode!);

    // Phase 20 Fields
    writer.writeBool(obj.irrigationStage != null);
    if (obj.irrigationStage != null) writer.writeString(obj.irrigationStage!);
    
    writer.writeBool(obj.soilMoisture != null);
    if (obj.soilMoisture != null) writer.writeString(obj.soilMoisture!);
    
    writer.writeBool(obj.weatherEvent != null);
    if (obj.weatherEvent != null) writer.writeString(obj.weatherEvent!);
    
    writer.writeBool(obj.spreadPattern != null);
    if (obj.spreadPattern != null) writer.writeString(obj.spreadPattern!);
    
    writer.writeBool(obj.lastTreatment != null);
    if (obj.lastTreatment != null) writer.writeString(obj.lastTreatment!);
    
    writer.writeBool(obj.dosage != null);
    if (obj.dosage != null) writer.writeString(obj.dosage!);
    
    // Phase 24.1
    writer.writeBool(obj.initialUserInput != null);
    if (obj.initialUserInput != null) writer.writeString(obj.initialUserInput!);
    
    writer.writeBool(obj.initialAiResponse != null);
    if (obj.initialAiResponse != null) writer.writeString(obj.initialAiResponse!);
    
    // Phase 24
    writer.writeBool(obj.thread != null);
    if (obj.thread != null) {
      writer.writeInt(obj.thread!.length);
      for (var item in obj.thread!) {
        writer.write(item);
      }
    }
  }
}
