import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_app/features/crop_diagnosis/providers/diagnosis_provider.dart';
import 'package:flutter_app/features/yield_prediction/providers/yield_provider.dart';

enum ActivityType { diagnosis, harvest }

class ActivityRecord {
  final String id;
  final ActivityType type;
  final String title;
  final String subtitle;
  final double confidence;
  final String? imagePath;
  final DateTime timestamp;
  final dynamic originalRecord;

  ActivityRecord({
    required this.id,
    required this.type,
    required this.title,
    required this.subtitle,
    required this.confidence,
    this.imagePath,
    required this.timestamp,
    required this.originalRecord,
  });
}

final dashboardActivityProvider = FutureProvider<List<ActivityRecord>>((ref) async {
  final diagnosisHistory = await ref.watch(diagnosisHistoryProvider.future);
  final yieldHistory = await ref.watch(yieldHistoryProvider.future);

  final List<ActivityRecord> combined = [];

  // Convert Diagnosis
  for (final d in diagnosisHistory) {
    combined.add(ActivityRecord(
      id: d.id,
      type: ActivityType.diagnosis,
      title: d.diseaseName,
      subtitle: "Crop Diagnosis",
      confidence: d.confidence,
      imagePath: d.imagePath,
      timestamp: d.timestamp,
      originalRecord: d,
    ));
  }

  // Convert Yield
  for (final y in yieldHistory) {
    combined.add(ActivityRecord(
      id: y.id,
      type: ActivityType.harvest,
      title: "${y.cropName} Yield",
      subtitle: "Yield Prediction - ${y.fieldName}",
      confidence: y.confidence / 100.0,
      timestamp: y.timestamp,
      originalRecord: y,
    ));
  }

  // Sort by timestamp descending
  combined.sort((a, b) => b.timestamp.compareTo(a.timestamp));

  return combined;
});
