import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'dart:io' as io;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_app/core/router/app_router.dart';
import 'package:flutter_app/core/theme/color_palette.dart';
import 'package:flutter_app/features/dashboard/presentation/providers/activity_provider.dart';
import '../../../profile/providers/profile_provider.dart';
import '../../../../core/api/path_enforcer.dart';
import '../../../../core/services/local_vault.dart';
import '../../../auth/providers/auth_provider.dart';
import 'package:flutter_app/core/localization/language_provider.dart';
import 'package:flutter_app/features/crop_diagnosis/providers/diagnosis_provider.dart';
import 'package:flutter_app/features/yield_prediction/providers/yield_provider.dart';

/// RecentActivityList - Displays a consolidated list of recent actions (Diagnoses & Yield Predictions)
class RecentActivityList extends ConsumerWidget {
  const RecentActivityList({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activityAsync = ref.watch(dashboardActivityProvider);
    final profileState = ref.watch(profileProvider);
    
    debugPrint("📋 RecentActivityList: Context -> Plot: ${profileState.selectedFieldId} | Cycle: ${profileState.activeCycleId}");

    ref.watch(languageProvider); // Watch the state to trigger rebuilds on language change
    final tr = ref.read(languageProvider.notifier);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              tr.translate('recent_activity'),
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: ColorPalette.textPrimary,
              ),
            ),
            TextButton(
              onPressed: () {
                context.push(AppRouter.activityLogPath);
              },
              child: Text(tr.translate('see_all')),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Expanded(
          child: activityAsync.when(
            data: (history) {
              if (history.isEmpty) {
                return _buildEmptyState(tr);
              }
              return ListView.builder(
                padding: EdgeInsets.zero,
                itemCount: history.length,
                itemBuilder: (context, index) {
                  return _buildActivityItem(context, ref, tr, history[index]);
                },
              );
            },
            loading: () => const Center(
              child: Padding(
                padding: EdgeInsets.all(24.0),
                child: CircularProgressIndicator(),
              ),
            ),
            error: (err, stack) => Center(child: Text("${tr.translate('error_loading_activity')}: $err")),
          ),
        ),
      ],
    );
  }

  Widget _buildActivityItem(BuildContext context, WidgetRef ref, LanguageNotifier tr, ActivityRecord record) {
    bool isDiagnosis = record.type == ActivityType.diagnosis;
    final profileState = ref.watch(profileProvider);
    final isUnassignedMode = profileState.selectedFieldId == PathEnforcer.unassignedFieldId;
    
    // Detect if this is a healthy plant diagnosis
    final bool isHealthy = isDiagnosis && (
      record.title.toLowerCase().contains('healthy') ||
      record.title.toLowerCase().contains('no visible disease') ||
      record.title.toLowerCase().contains('no disease')
    );
    
    // Context-aware subtitle for diagnosis
    final String diagnosisSubtitle = isHealthy ? tr.translate('healthy_plant') : tr.translate('detected_issue');

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
            final isLargeScreen = MediaQuery.of(context).size.width > 900;
            if (isLargeScreen) {
              context.push(AppRouter.activityLogPath, extra: record.id);
            } else {
              if (isDiagnosis) {
                context.push(AppRouter.diagnosisDetailsPath, extra: record.originalRecord);
              } else {
                context.push(AppRouter.yieldDetailsPath, extra: record.originalRecord);
              }
            }
          },
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                // Image Thumbnail or Icon
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: isDiagnosis 
                        ? (isHealthy ? Colors.green.shade50 : ColorPalette.rustRed.withValues(alpha: 0.1))
                        : ColorPalette.goldenSunlight.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: (isDiagnosis && record.imagePath != null && record.imagePath!.isNotEmpty)
                        ? (kIsWeb || record.imagePath!.startsWith('data:'))
                            ? Image.network(
                                record.imagePath!,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => _buildFallbackIcon(record),
                              )
                            : Image.file(
                                io.File(record.imagePath!),
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => _buildFallbackIcon(record),
                              )
                        : _buildFallbackIcon(record),
                  ),
                ),
                
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
                            isDiagnosis ? diagnosisSubtitle : tr.translate('yield_prediction'),
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
                      Builder(
                        builder: (context) {
                          final diagnosisState = ref.watch(diagnosisProvider);
                          final yieldState = ref.watch(yieldProvider);
                          
                          String displayTitle = record.title;
                          if (isDiagnosis) {
                            if (diagnosisState.activeRecordId == record.id && diagnosisState.diagnosisResult != null) {
                              displayTitle = diagnosisState.diagnosisResult!['disease_name'] ?? record.title;
                            } else if (!record.title.contains(' ')) {
                              displayTitle = tr.translate(record.title);
                            }
                          } else {
                            if (yieldState.activeRecordId == record.id && yieldState.result != null) {
                              final localizedCrop = tr.translate((record.cropName ?? 'onion').toLowerCase());
                              final yieldVal = yieldState.result!.expectedYield.toStringAsFixed(1);
                              final qtlAcre = tr.translate('qtl_acre');
                              displayTitle = '$yieldVal $qtlAcre - $localizedCrop';
                            } else if (!record.title.contains(' - ')) {
                              displayTitle = tr.translate(record.title);
                            }
                          }

                          return Text(
                            displayTitle,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                              color: isDiagnosis 
                                ? (isHealthy ? ColorPalette.emeraldGreen : ColorPalette.rustRed)
                                : ColorPalette.textPrimary,
                            ),
                          );
                        }
                      ),
                      const SizedBox(height: 4),
                      if (!isDiagnosis)
                        Text(
                          '${record.subtitle} • ${_formatDate(tr, record.timestamp, ref)}',
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 10,
                          ),
                        )
                      else
                        Text(
                          _formatDate(tr, record.timestamp, ref),
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 10,
                          ),
                        ),
                    ],
                  ),
                ),

                // Confidence / Status / Language Badge
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    if (!isUnassignedMode) _buildBadge(tr, record),
                    if (record.languageCode != null) ...[
                      const SizedBox(height: 4),
                      _buildLanguageBadge(tr, record.languageCode!),
                    ],
                  ],
                ),

                // 🚚 RE-HOME ACTION (Phase 4 Addition)
                if (isUnassignedMode)
                  IconButton(
                    icon: const Icon(Icons.drive_file_move_rtl_rounded, color: Colors.orange),
                     onPressed: () => _showRehomePicker(context, ref, tr, record),
                    tooltip: tr.translate('move_to_plot'),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }


  Widget _buildFallbackIcon(ActivityRecord record) {
    final bool isDiagnosis = record.type == ActivityType.diagnosis;
    final bool isHealthy = isDiagnosis && (
      record.title.toLowerCase().contains('healthy') ||
      record.title.toLowerCase().contains('no visible disease') ||
      record.title.toLowerCase().contains('no disease')
    );

    return Icon(
      isDiagnosis ? Icons.local_hospital_rounded : Icons.trending_up_rounded,
      color: isDiagnosis 
          ? (isHealthy ? ColorPalette.emeraldGreen : ColorPalette.rustRed)
          : ColorPalette.goldenSunlight,
      size: 20,
    );
  }


  Widget _buildBadge(LanguageNotifier tr, ActivityRecord record) {
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
        isYield ? tr.translate('yield_prediction') : "${(record.confidence * 100).toInt()}% ${tr.translate('confidence_suffix')}",
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }

  String _formatDate(LanguageNotifier tr, DateTime date, WidgetRef ref) {
    final now = DateTime.now();
    final difference = now.difference(date);
    if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        return "${difference.inMinutes}${tr.translate('m_ago')}";
      }
      return "${difference.inHours}${tr.translate('h_ago')}";
    } else if (difference.inDays == 1) {
      return tr.translate('yesterday');
    } else {
      final months = ['jan', 'feb', 'mar', 'apr', 'may', 'jun', 'jul', 'aug', 'sep', 'oct', 'nov', 'dec'];
      final monthKey = months[date.month - 1];
      return "${date.day} ${tr.translate(monthKey)} ${date.year}";
    }
  }

  Widget _buildEmptyState(LanguageNotifier tr) {
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
          Text(
            tr.translate('no_activity_yet'),
            style: const TextStyle(
              color: ColorPalette.textSecondary,
              fontWeight: FontWeight.w600,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            tr.translate('start_scan_prediction_hint'),
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.grey, fontSize: 13),
          ),
        ],
      ),
    );
  }
  void _showRehomePicker(BuildContext context, WidgetRef ref, LanguageNotifier tr, ActivityRecord record) {
    final profileState = ref.read(profileProvider);
    final activePlots = profileState.fields.where((f) => f.id != PathEnforcer.unassignedFieldId).toList();

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(tr.translate('move_record_to_plot'), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(tr.translate('select_destination_plot')),
            const SizedBox(height: 16),
            ...activePlots.map((plot) => ListTile(
              leading: const Icon(Icons.landscape_rounded, color: ColorPalette.emeraldGreen),
              title: Text(plot.name),
              subtitle: Text(plot.soilType),
              onTap: () async {
                final authState = ref.read(authStateProvider);
                final userId = authState.value?.id ?? "anonymous";
                final vault = LocalVault();
                final oldKey = PathEnforcer.localCompositeKey(
                  userId: userId,
                  fieldId: PathEnforcer.unassignedFieldId, 
                  cycleId: PathEnforcer.defaultCycleId, 
                  activityId: record.id
                );
                
                await vault.rehomeRecord(
                  oldKey, 
                  userId: userId,
                  fieldId: plot.id, 
                  cycleId: PathEnforcer.defaultCycleId
                );
                ref.invalidate(dashboardActivityProvider);
                if (context.mounted) Navigator.pop(context);
                
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("${tr.translate('moved_successfully')} (${plot.name})"))
                  );
                }
              },
            )),
          ],
        ),
      ),
    );
  }

  Widget _buildLanguageBadge(LanguageNotifier tr, String languageCode) {
    String label = languageCode.toUpperCase();
    final Map<String, String> langMap = {
      'hi': 'Hindi',
      'ta': 'Tamil',
      'kn': 'Kannada',
      'te': 'Telugu',
      'ml': 'Malayalam',
      'en': 'English'
    };
    label = langMap[languageCode] ?? label;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        "${tr.translate('scan_in')} $label",
        style: TextStyle(
          fontSize: 8,
          fontWeight: FontWeight.w500,
          color: Colors.grey.shade600,
        ),
      ),
    );
  }
}
