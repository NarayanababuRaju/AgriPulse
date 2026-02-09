import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'dart:io' as io;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_app/core/theme/color_palette.dart';
import 'package:flutter_app/features/dashboard/presentation/providers/activity_provider.dart';
import 'package:flutter_app/features/crop_diagnosis/presentation/widgets/diagnosis_details_pane.dart';
import 'package:flutter_app/features/yield_prediction/presentation/widgets/yield_details_pane.dart';
import 'package:flutter_app/core/localization/language_provider.dart';
import 'package:flutter_app/core/widgets/language_selector.dart';
import 'package:flutter_app/core/router/app_router.dart';
import 'package:flutter_app/core/services/local_vault.dart';
import 'package:flutter_app/features/profile/providers/profile_provider.dart';
import 'package:flutter_app/features/auth/providers/auth_provider.dart';
import 'package:flutter_app/features/crop_diagnosis/providers/diagnosis_provider.dart';
import 'package:flutter_app/features/yield_prediction/providers/yield_provider.dart';

class ActivityHistoryScreen extends ConsumerStatefulWidget {
  final String? initialSelectionId;
  const ActivityHistoryScreen({super.key, this.initialSelectionId});

  @override
  ConsumerState<ActivityHistoryScreen> createState() => _ActivityHistoryScreenState();
}

class _ActivityHistoryScreenState extends ConsumerState<ActivityHistoryScreen> {
  ActivityRecord? _selectedRecord;
  String _searchQuery = "";
  final Set<String> _deletedIds = {};

  @override
  Widget build(BuildContext context) {
    final activityAsync = ref.watch(dashboardActivityProvider);
    final tr = ref.watch(languageProvider.notifier);
    final isLargeScreen = MediaQuery.of(context).size.width > 900;

    return Scaffold(
      backgroundColor: ColorPalette.offWhite,
      appBar: AppBar(
        title: Text(
          tr.translate('activity_log'),
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: ColorPalette.textPrimary,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => context.pop(),
        ),
        actions: [
          Center(
            child: LanguageSelector(
              textColor: ColorPalette.textPrimary,
              onChanged: (lang) {
                if (_selectedRecord == null) return;
                
                if (_selectedRecord!.type == ActivityType.diagnosis) {
                  final controller = ref.read(diagnosisProvider.notifier);
                  final record = _selectedRecord!.originalRecord;
                  
                  if (ref.read(diagnosisProvider).activeRecordId != record.id) {
                    controller.loadRecord(record);
                  }
                  controller.translateDiagnosis(lang.backendName);
                } else {
                  final controller = ref.read(yieldProvider.notifier);
                  final record = _selectedRecord!.originalRecord;
                  
                  if (ref.read(yieldProvider).activeRecordId != record.id) {
                    controller.loadRecord(record);
                  }
                  controller.translateResult(lang.backendName);
                }
              },
            ),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: activityAsync.when(
        data: (records) {
          final filteredRecords = records.where((r) => 
            !_deletedIds.contains(r.id) && (
              r.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
              r.subtitle.toLowerCase().contains(_searchQuery.toLowerCase())
            )
          ).toList();

          // 🛡️ Selection Validation: Ensure the selected record still exists in the master list
          // This handles cases where a record is deleted or filtering changes
          if (_selectedRecord != null) {
            final bool exists = filteredRecords.any((r) => r.id == _selectedRecord!.id);
            if (!exists) {
              _selectedRecord = null;
            }
          }

          // 🎯 Auto-Selection Logic: Only runs if nothing is selected and we have data
          if (_selectedRecord == null && filteredRecords.isNotEmpty) {
            if (widget.initialSelectionId != null) {
              _selectedRecord = records.firstWhere(
                (r) => r.id == widget.initialSelectionId,
                orElse: () => filteredRecords.first,
              );
            } else {
              _selectedRecord = filteredRecords.first;
            }
          }

          if (isLargeScreen) {
            return Row(
              children: [
                // 1. Sidebar (Master)
                Container(
                  width: 350,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border(right: BorderSide(color: Colors.grey.shade100)),
                  ),
                  child: Column(
                    children: [
                      _buildSearchField(tr),
                      Expanded(
                        child: ListView.builder(
                          itemCount: filteredRecords.length,
                          itemBuilder: (context, index) => _buildActivityTile(filteredRecords[index], tr),
                        ),
                      ),
                      _buildClearHistoryButton(tr),
                    ],
                  ),
                ),
                // 2. Detail Area
                Expanded(
                  child: Container(
                    color: ColorPalette.offWhite,
                    child: _selectedRecord == null 
                      ? _buildNoSelection(tr)
                      : _buildDetailPane(tr, isCompact: true),
                  ),
                ),
              ],
            );
          } else {
            // Mobile: Standard List (Stack navigation would be handled by router, 
            // but for "landing page" feel we'll use a local detail view transition)
            return Column(
              children: [
                _buildSearchField(tr),
                Expanded(
                  child: ListView.builder(
                    itemCount: filteredRecords.length,
                    itemBuilder: (context, index) => _buildActivityTile(filteredRecords[index], tr),
                  ),
                ),
                _buildClearHistoryButton(tr),
              ],
            );
          }
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text("Error: $err")),
      ),
    );
  }

  Widget _buildSearchField(dynamic tr) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: TextField(
        onChanged: (val) => setState(() => _searchQuery = val),
        decoration: InputDecoration(
          hintText: tr.translate('search_history_hint'),
          prefixIcon: const Icon(Icons.search, size: 20),
          filled: true,
          fillColor: const Color(0xFFF8FAFC),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }

  Widget _buildActivityTile(ActivityRecord record, dynamic tr) {
    final isSelected = _selectedRecord?.id == record.id;
    final bool isDiagnosis = record.type == ActivityType.diagnosis;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: InkWell(
        onTap: () {
          if (MediaQuery.of(context).size.width > 900) {
            setState(() => _selectedRecord = record);
          } else {
            // Push to individual details screen on mobile
            if (isDiagnosis) {
              context.push(AppRouter.diagnosisDetailsPath, extra: record.originalRecord);
            } else {
              context.push(AppRouter.yieldDetailsPath, extra: record.originalRecord);
            }
          }
        },
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isSelected ? ColorPalette.emeraldGreen.withValues(alpha: 0.05) : Colors.transparent,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected ? ColorPalette.emeraldGreen.withValues(alpha: 0.1) : Colors.transparent,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: isDiagnosis ? ColorPalette.rustRed.withValues(alpha: 0.1) : ColorPalette.emeraldGreen.withValues(alpha: 0.1),
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
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
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
                          style: GoogleFonts.outfit(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            color: isSelected ? ColorPalette.emeraldGreen : ColorPalette.textPrimary,
                          ),
                        );
                      }
                    ),
                    Text(
                      !isDiagnosis && !record.subtitle.contains(' • ') 
                          ? '${record.subtitle} • ${_formatDate(tr, record.timestamp, ref)}'
                          : (record.subtitle.contains(' • ') ? record.subtitle : tr.translate(record.subtitle)),
                      style: GoogleFonts.outfit(
                        fontSize: 12,
                        color: ColorPalette.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    _formatDate(tr, record.timestamp, ref),
                    style: GoogleFonts.outfit(fontSize: 10, color: Colors.grey),
                  ),
                  if (isSelected)
                    Container(
                      margin: const EdgeInsets.only(top: 4),
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(color: ColorPalette.emeraldGreen, shape: BoxShape.circle),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailPane(dynamic tr, {bool isCompact = false}) {
    return Column(
      children: [
        // Top Action Bar for Detail
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
          color: Colors.white,
          child: Row(
            children: [
              const Icon(Icons.description_outlined, color: ColorPalette.rustRed, size: 24),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    tr.translate('detailed_report'),
                    style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  Text(
                    _formatDate(tr, _selectedRecord!.timestamp, ref),
                    style: GoogleFonts.outfit(fontSize: 11, color: Colors.grey),
                  ),
                ],
              ),
              // Crop details
              if (_selectedRecord?.cropName != null)
                _buildInfoBar(_selectedRecord!, tr),
              const Spacer(),
              _buildActionButton(Icons.share_outlined, () {}),
              const SizedBox(width: 8),
              _buildActionButton(Icons.file_download_outlined, () {}),
              const SizedBox(width: 8),
              _buildActionButton(
                Icons.delete_outline_rounded, 
                () => _showDeleteRecordDialog(context, ref, tr, _selectedRecord!),
                color: ColorPalette.rustRed,
              ),
              const SizedBox(width: 8),
              _buildActionButton(Icons.more_vert_rounded, () {}),
            ],
          ),
        ),
        // Content - No outer ScrollView here for compact mode to allow modular internal scrolls
        Expanded(
          child: _selectedRecord!.type == ActivityType.diagnosis
            ? DiagnosisDetailsPane(record: _selectedRecord!.originalRecord, isCompact: isCompact)
            : YieldDetailsPane(record: _selectedRecord!.originalRecord, isCompact: isCompact),
        ),
      ],
    );
  }

  Widget _buildInfoBar(ActivityRecord record, dynamic tr) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.grass, color: ColorPalette.emeraldGreen, size: 16),
          const SizedBox(width: 8),
          Text(
            tr.translate(record.cropName ?? record.title),
            style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: ColorPalette.textPrimary, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(IconData icon, VoidCallback onTap, {Color? color}) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
      ),
      child: IconButton(
        icon: Icon(icon, size: 20, color: color ?? ColorPalette.textPrimary),
        onPressed: onTap,
      ),
    );
  }

  Widget _buildFallbackIcon(ActivityRecord record) {
    final bool isDiagnosis = record.type == ActivityType.diagnosis;
    return Icon(
      isDiagnosis ? Icons.local_hospital_rounded : Icons.trending_up_rounded,
      color: isDiagnosis ? ColorPalette.rustRed : ColorPalette.emeraldGreen,
      size: 20,
    );
  }

  Widget _buildNoSelection(dynamic tr) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.history_edu_rounded, size: 80, color: Colors.grey.shade200),
          const SizedBox(height: 24),
          Text(
            tr.translate('select_record_detail'),
            style: GoogleFonts.outfit(fontSize: 18, color: ColorPalette.textSecondary),
          ),
        ],
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

  Widget _buildClearHistoryButton(dynamic tr) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Align(
        alignment: Alignment.centerLeft,
        child: TextButton.icon(
          onPressed: () => _showClearHistoryDialog(context, ref, tr),
          icon: const Icon(Icons.delete_outline_rounded, color: ColorPalette.rustRed, size: 20),
          label: Text(
            tr.translate('clear_history'),
            style: GoogleFonts.outfit(
              color: ColorPalette.rustRed, 
              fontWeight: FontWeight.bold
            ),
          ),
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            backgroundColor: ColorPalette.rustRed.withValues(alpha: 0.05),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
      ),
    );
  }

  Future<void> _showClearHistoryDialog(BuildContext context, WidgetRef ref, dynamic tr) async {
    final shouldClear = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(tr.translate('clear_history')),
        content: Text(tr.translate('clear_history_confirm')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(tr.translate('cancel')),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              tr.translate('clear'), 
              style: const TextStyle(color: ColorPalette.rustRed, fontWeight: FontWeight.bold)
            ),
          ),
        ],
      ),
    );

    if (shouldClear == true) {
      final authState = ref.read(authStateProvider);
      final profileState = ref.read(profileProvider);
      
      final userId = authState.value?.id;
      final fieldId = profileState.selectedFieldId;
      final cycleId = profileState.activeCycleId;

      if (userId != null && fieldId != null && cycleId != null) {
        // Clear from LocalVault
        await LocalVault().clearHistory(
          userId: userId, 
          fieldId: fieldId, 
          cycleId: cycleId
        );

        // Refresh Providers
        ref.invalidate(diagnosisHistoryProvider);
        ref.invalidate(yieldHistoryProvider);
        // dashboardActivityProvider watches these, so it will auto-update
        
        if (context.mounted) {
           ScaffoldMessenger.of(context).showSnackBar(
             SnackBar(content: Text("${tr.translate('clear_history')} ${tr.translate('completed') ?? 'Completed'}")),
           );
           // Clear selection
           setState(() {
             _selectedRecord = null;
             _deletedIds.clear();
           });
        }
      }
    }
  }

  Future<void> _showDeleteRecordDialog(BuildContext context, WidgetRef ref, dynamic tr, ActivityRecord record) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('${tr.translate('delete')[0].toUpperCase()}${tr.translate('delete').substring(1)} ${record.title}'),
        content: Text(tr.translate('delete_record_confirm') ?? 'Are you sure you want to remove this record?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(tr.translate('cancel')),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              tr.translate('delete') ?? 'Delete', 
              style: const TextStyle(color: ColorPalette.rustRed, fontWeight: FontWeight.bold)
            ),
          ),
        ],
      ),
    );

    if (shouldDelete == true) {
      // 🎯 Pre-emptive Neighbor Calculation & State Update
      ActivityRecord? nextSelection;
      final activityState = ref.read(dashboardActivityProvider);
      
      activityState.whenData((records) {
        final filtered = records.where((r) => !_deletedIds.contains(r.id)).toList();
        final currentIndex = filtered.indexWhere((r) => r.id == record.id);
        
        if (currentIndex != -1 && filtered.length > 1) {
          if (currentIndex < filtered.length - 1) {
            nextSelection = filtered[currentIndex + 1];
          } else {
            nextSelection = filtered[currentIndex - 1];
          }
        }
      });

      // Update state IMMEDIATELY to prevent build-method race conditions
      setState(() {
        _deletedIds.add(record.id);
        if (_selectedRecord?.id == record.id) {
          _selectedRecord = nextSelection;
        }
      });

      // Perform actual deletion asynchronously
      if (record.type == ActivityType.diagnosis) {
        await ref.read(diagnosisProvider.notifier).deleteRecord(record.id);
      } else {
        await ref.read(yieldProvider.notifier).deleteRecord(record.id);
      }

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(tr.translate('record_deleted') ?? 'Record deleted')),
        );
      }
    }
  }
}
