import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_app/features/crop_diagnosis/providers/diagnosis_provider.dart';
import 'package:flutter_app/features/yield_prediction/providers/yield_provider.dart';
import 'package:flutter_app/core/localization/language_provider.dart';

enum ActivityType { diagnosis, harvest }

class ActivityRecord {
  final String id;
  final ActivityType type;
  final String title; // Can be a key or a dynamic string
  final String subtitle; // Can be a key or a dynamic string
  final Map<String, String>? titleArgs;
  final double confidence;
  final String? imagePath;
  final String? cropName;
  final DateTime timestamp;
  final String? languageCode;
  final dynamic originalRecord;

  ActivityRecord({
    required this.id,
    required this.type,
    required this.title,
    required this.subtitle,
    this.titleArgs,
    required this.confidence,
    this.imagePath,
    this.cropName,
    required this.timestamp,
    this.languageCode,
    required this.originalRecord,
  });
}

final dashboardActivityProvider = FutureProvider<List<ActivityRecord>>((ref) async {
  ref.watch(languageProvider); // Rebuild when language changes
  final diagnosisHistory = await ref.watch(diagnosisHistoryProvider.future);
  final yieldHistory = await ref.watch(yieldHistoryProvider.future);

  final List<ActivityRecord> combined = [];

  // Convert Diagnosis
  for (final d in diagnosisHistory) {
    combined.add(ActivityRecord(
      id: d.id,
      type: ActivityType.diagnosis,
      title: d.diseaseName, // Disease names are usually dynamic from AI
      subtitle: 'crop_doctor',
      confidence: d.confidence,
      cropName: d.cropName ?? (d.diseaseName.toLowerCase().contains("onion") ? "onion" : "onion"),
      imagePath: d.imagePath,
      timestamp: d.timestamp,
      languageCode: d.languageCode,
      originalRecord: d,
    ));
  }

  // Convert Yield
  for (final y in yieldHistory) {
    final tr = ref.read(languageProvider.notifier);
    final localizedCrop = tr.translate(y.cropName.toLowerCase());
    final yieldVal = y.expectedYield.toStringAsFixed(1);
    final qtlAcre = tr.translate('qtl_acre');
    
    combined.add(ActivityRecord(
      id: y.id,
      type: ActivityType.harvest,
      title: '$yieldVal $qtlAcre - $localizedCrop', 
      subtitle: y.fieldName, // Time ago is added in the UI usually, but we'll maintain field consistency
      confidence: y.confidence / 100.0,
      cropName: y.cropName.toLowerCase(),
      timestamp: y.timestamp,
      languageCode: y.languageCode,
      originalRecord: y,
    ));
  }

  // Sort by timestamp descending
  combined.sort((a, b) => b.timestamp.compareTo(a.timestamp));

  return combined;
});
