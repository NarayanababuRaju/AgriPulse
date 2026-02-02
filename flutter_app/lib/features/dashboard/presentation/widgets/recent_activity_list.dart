import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_app/core/theme/color_palette.dart';
import 'package:flutter_app/features/dashboard/presentation/providers/activity_provider.dart';
import 'package:flutter_app/core/router/app_router.dart';

/// RecentActivityList - Displays a consolidated list of recent actions (Diagnoses & Yield Predictions)
class RecentActivityList extends ConsumerWidget {
  const RecentActivityList({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activityAsync = ref.watch(dashboardActivityProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              "Recent Activity",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: ColorPalette.textPrimary,
              ),
            ),
            TextButton(
              onPressed: () {
                // TODO: View all activity
              },
              child: const Text("See All"),
            ),
          ],
        ),
        const SizedBox(height: 8),
        activityAsync.when(
          data: (history) {
            if (history.isEmpty) {
              return _buildEmptyState();
            }
            // Show top 5 recent items in dashboard
            final recentItems = history.take(5).toList();
            return Column(
              children: recentItems.map((record) => _buildActivityItem(context, record)).toList(),
            );
          },
          loading: () => const Center(
            child: Padding(
              padding: EdgeInsets.all(24.0),
              child: CircularProgressIndicator(),
            ),
          ),
          error: (err, stack) => Center(child: Text("Error loading activity: $err")),
        ),
      ],
    );
  }

  Widget _buildActivityItem(BuildContext context, ActivityRecord record) {
    bool isDiagnosis = record.type == ActivityType.diagnosis;
    
    // Detect if this is a healthy plant diagnosis
    final bool isHealthy = isDiagnosis && (
      record.title.toLowerCase().contains('healthy') ||
      record.title.toLowerCase().contains('no visible disease') ||
      record.title.toLowerCase().contains('no disease')
    );
    
    // Context-aware subtitle for diagnosis
    final String diagnosisSubtitle = isHealthy ? "Healthy Plant" : "Detected Issue";

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            if (isDiagnosis) {
              context.push('/diagnosis-details', extra: record.originalRecord);
            } else {
              context.push(AppRouter.yieldDetailsPath, extra: record.originalRecord);
            }
          },
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                // Crop Doctor Icon for diagnosis entries (matching Smart Tools)
                if (isDiagnosis)
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: isHealthy ? Colors.green.shade50 : ColorPalette.rustRed.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.local_hospital_rounded,
                      color: isHealthy ? ColorPalette.emeraldGreen : ColorPalette.rustRed,
                      size: 20,
                    ),
                  ),
                
                // Yield Icon
                if (!isDiagnosis)
                  _buildTypeIcon(record.type),
                
                const SizedBox(width: 12),
                
                // Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Type indicator with context-aware styling
                      Row(
                        children: [
                          Icon(
                            isDiagnosis 
                              ? (isHealthy ? Icons.check_circle_outline : Icons.warning_amber_rounded)
                              : Icons.trending_up,
                            size: 14,
                            color: isDiagnosis 
                              ? (isHealthy ? ColorPalette.emeraldGreen : ColorPalette.rustRed)
                              : Colors.orange,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            isDiagnosis ? diagnosisSubtitle : "Yield Prediction",
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: isDiagnosis 
                                ? (isHealthy ? ColorPalette.emeraldGreen : ColorPalette.rustRed)
                                : Colors.orange,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        record.title,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: isDiagnosis 
                            ? (isHealthy ? ColorPalette.emeraldGreen : ColorPalette.rustRed)
                            : ColorPalette.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _formatDate(record.timestamp),
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ),

                // Confidence / Status Badge
                _buildBadge(record),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDiagnosisIcon(bool isHealthy) {
    return Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        color: isHealthy ? Colors.green.shade50 : Colors.red.shade50,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(
        isHealthy ? Icons.check_circle_outline_rounded : Icons.warning_amber_rounded,
        color: isHealthy ? ColorPalette.emeraldGreen : ColorPalette.rustRed,
        size: 24,
      ),
    );
  }

  Widget _buildThumbnail(String path) {
    ImageProvider imageProvider;
    if (path.startsWith("assets/")) {
      imageProvider = AssetImage(path);
    } else if (kIsWeb) {
      if (path.startsWith("http") || path.startsWith("blob:")) {
        imageProvider = NetworkImage(path);
      } else {
        imageProvider = const AssetImage("assets/images/logo.png");
      }
    } else {
      imageProvider = FileImage(File(path));
    }

    return Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        image: DecorationImage(
          image: imageProvider,
          fit: BoxFit.cover,
        ),
      ),
    );
  }

  Widget _buildTypeIcon(ActivityType type) {
    final isYield = type == ActivityType.harvest;
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: isYield ? ColorPalette.goldenSunlight.withValues(alpha: 0.1) : Colors.blue.shade50,
        shape: BoxShape.circle,
      ),
      child: Icon(
        isYield ? Icons.trending_up_rounded : Icons.biotech_outlined,
        color: isYield ? ColorPalette.goldenSunlight : Colors.blue,
        size: 20,
      ),
    );
  }

  Widget _buildBadge(ActivityRecord record) {
    final isHealthy = record.title.toLowerCase().contains("healthy");
    final isYield = record.type == ActivityType.harvest;
    
    Color color = isYield ? Colors.blue : (isHealthy ? ColorPalette.emeraldGreen : ColorPalette.rustRed);
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        isYield ? "PREDICTION" : "${(record.confidence * 100).toInt()}% CONF",
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        return "${difference.inMinutes}m ago";
      }
      return "${difference.inHours}h ago";
    } else if (difference.inDays == 1) {
      return "Yesterday";
    } else {
      return "${date.day}/${date.month}/${date.year}";
    }
  }

  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Column(
        children: [
          Icon(Icons.history_toggle_off_rounded, size: 64, color: Colors.grey.shade200),
          const SizedBox(height: 16),
          const Text(
            "No activity yet",
            style: TextStyle(
              color: ColorPalette.textSecondary,
              fontWeight: FontWeight.w600,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            "Start a crop scan or yield prediction to see history",
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey, fontSize: 13),
          ),
        ],
      ),
    );
  }
}
