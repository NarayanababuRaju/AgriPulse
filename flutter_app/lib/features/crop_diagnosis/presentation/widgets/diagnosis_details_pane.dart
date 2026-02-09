import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_app/core/theme/color_palette.dart';
import 'package:flutter_app/features/crop_diagnosis/models/diagnosis_record.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_app/features/crop_diagnosis/models/thread_item.dart';
import 'package:flutter_app/core/localization/language_provider.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/router/app_router.dart';
import '../../providers/diagnosis_provider.dart';

final activeDiagnosisViewProvider = StateProvider.autoDispose<int>((ref) => 0); // 0: Initial, 1: Refined

class DiagnosisDetailsPane extends ConsumerWidget {
  final DiagnosisRecord record;
  final bool isCompact;

  const DiagnosisDetailsPane({
    super.key, 
    required this.record,
    this.isCompact = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tr = ref.watch(languageProvider.notifier);
    final bool isHealthy = record.diseaseName.toLowerCase().contains('healthy') || 
                           record.diseaseName.toLowerCase().contains('no disease');
    final Color statusColor = isHealthy ? ColorPalette.emeraldGreen : ColorPalette.rustRed;
    
    final diagnosisState = ref.watch(diagnosisProvider);
    final bool isCorrectRecord = diagnosisState.activeRecordId == record.id;
    
    // Prefer state if available for this specific record (translation/refinement support)
    final String diseaseName = isCorrectRecord && diagnosisState.diagnosisResult != null 
        ? (diagnosisState.diagnosisResult!['disease_name'] ?? record.diseaseName)
        : record.diseaseName;
        
    final String summary = isCorrectRecord && diagnosisState.diagnosisResult != null 
        ? (diagnosisState.diagnosisResult!['treatment_recommendation'] ?? record.treatmentSummary)
        : record.treatmentSummary;

    final String? adjustment = isCorrectRecord && diagnosisState.diagnosisResult != null 
        ? (diagnosisState.diagnosisResult!['treatment_adjustment'] ?? record.treatmentAdjustment)
        : record.treatmentAdjustment;

    final String? reasoning = isCorrectRecord && diagnosisState.diagnosisResult != null 
        ? (diagnosisState.diagnosisResult!['refinement_reasoning'] ?? record.refinementReasoning)
        : record.refinementReasoning;

    if (diagnosisState.isAnalyzing && isCorrectRecord) {
      return const Center(child: CircularProgressIndicator());
    }

    if (isCompact) {
      return _buildControlCenterLayout(tr, statusColor, isHealthy, diseaseName, summary, adjustment, reasoning);
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. Header & Severity Card Row
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 3,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        isHealthy ? tr.translate('health_status') : tr.translate('diagnosis_analysis'),
                        style: GoogleFonts.outfit(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: statusColor,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      "${tr.translate('crop_doctor')}:\n$diseaseName",
                      style: GoogleFonts.outfit(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: ColorPalette.textPrimary,
                        height: 1.1,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      tr.translate('gemini_hint'),
                      style: GoogleFonts.outfit(
                        fontSize: 14,
                        color: ColorPalette.textSecondary,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Action Buttons for History View
                    Row(
                      children: [
                        ElevatedButton.icon(
                          onPressed: () {
                            ref.read(diagnosisProvider.notifier).loadRecord(record);
                            context.push(AppRouter.cropDoctorPath);
                          },
                          icon: const Icon(Icons.auto_awesome_outlined, size: 18),
                          label: Text(tr.translate('ask_second_opinion')),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: ColorPalette.emeraldGreen,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            elevation: 0,
                          ),
                        ),
                        const SizedBox(width: 12),
                        OutlinedButton.icon(
                          onPressed: () {}, // Handled by host screen sharing logic
                          icon: const Icon(Icons.share_outlined, size: 18),
                          label: Text(tr.translate('share')),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: ColorPalette.textSecondary,
                            side: BorderSide(color: Colors.grey.shade300),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 24),
              // No severity card here anymore, moving to unified section below
            ],
          ),
          
          const SizedBox(height: 32),

          // 2. Info Bar (Plot & Date)
          Wrap(
            spacing: 16,
            runSpacing: 12,
            children: [
              _buildInfoChip(Icons.location_on_rounded, tr.translate('main_plot_north')),
              _buildInfoChip(Icons.calendar_today_rounded, _formatDate(record.timestamp, tr)),
              if (record.languageCode != null)
                _buildLanguageInfo(record.languageCode!, tr),
            ],
          ),

          const SizedBox(height: 32),

          // IMAGE PANEL (Phase 20+)
          _buildImageHeader(record.imagePath, tr: tr),

          const SizedBox(height: 32),

          // 3. Middle Row: Findings & Unified Metrics
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Diagnostic Findings
              Expanded(
                flex: 3,
                child: _buildFindingsCard(record.farmerInput ?? tr.translate('no_feedback_provided'), tr, thread: record.thread, reasoning: reasoning),
              ),
              const SizedBox(width: 24),
              // Unified Metrics (Restored & Consolidated)
              Expanded(
                flex: 2,
                child: _buildUnifiedMetricsCard(tr),
              ),
            ],
          ),

          const SizedBox(height: 32),

          // 4. Bottom Row: Recommendations & Environment
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Recommendations
              Expanded(
                flex: 3,
                child: Column(
                  children: [
                    Consumer(
                      builder: (context, ref, _) {
                        final activeView = ref.watch(activeDiagnosisViewProvider);
                        final isRefinedView = activeView == 1 && adjustment != null;
                        
                        return _buildActionCard(
                          isRefinedView ? tr.translate('treatment_adjustment_label') : tr.translate('ai_recommendation'), 
                          isRefinedView 
                            ? adjustment
                            : (adjustment != null 
                                ? _deduplicateTreatment(summary, adjustment)
                                : summary), 
                          isRefinedView ? Icons.auto_awesome : Icons.medical_services_outlined,
                          isRefinedView ? Colors.orange : ColorPalette.emeraldGreen,
                          isSecondary: isRefinedView,
                        );
                      }
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 24),
              // Environmental Status
              Expanded(
                flex: 2,
                child: _buildEnvironmentCard(
                  record.temperature ?? 23.9, 
                  record.humidity ?? 73.0,
                  tr,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildControlCenterLayout(dynamic tr, Color statusColor, bool isHealthy, String diseaseName, String summary, String? adjustment, String? reasoning) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        children: [
          // 1. Header Area
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      diseaseName,
                      style: GoogleFonts.outfit(fontSize: 28, fontWeight: FontWeight.bold, color: ColorPalette.textPrimary),
                    ),
                    Text(
                      isHealthy ? tr.translate('health_status') : tr.translate('diagnosis_analysis'),
                      style: GoogleFonts.outfit(fontSize: 12, color: statusColor, fontWeight: FontWeight.bold, letterSpacing: 1.2),
                    ),
                  ],
                ),
              ),
              _buildInfoChip(Icons.calendar_today_rounded, _formatDate(record.timestamp, tr)),
            ],
          ),
          const SizedBox(height: 24),
          
          // 2. Main Workspace (2-Column Layout)
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // LEFT COLUMN: Evidence & Findings
                Expanded(
                  flex: 4,
                  child: Column(
                    children: [
                      _buildImageHeader(record.imagePath, isCompact: true, isBoxed: true, tr: tr),
                      const SizedBox(height: 16),
                      // Findings Panel (Now correctly Expanded within the Column)
                      Expanded(
                        child: _buildScrollablePanel(
                          title: tr.translate('findings'),
                          icon: Icons.verified_user_outlined,
                          child: _buildFindingsCardContent(record.farmerInput ?? tr.translate('no_feedback_provided'), tr, thread: record.thread, reasoning: reasoning),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 24),
                // RIGHT COLUMN: Findings & Treatment
                Expanded(
                  flex: 6,
                  child: Column(
                    children: [
                      _buildUnifiedMetricsCard(tr),
                      const SizedBox(height: 16),
                      // Treatment Panel
                      Expanded(
                        flex: 6,
                        child: _buildScrollablePanel(
                          title: tr.translate('treatment_plan'),
                          icon: Icons.medication_outlined,
                          child: Column(
                            children: [
                              Consumer(
                                builder: (context, ref, _) {
                                  final activeView = ref.watch(activeDiagnosisViewProvider);
                                  final isRefinedView = activeView == 1 && adjustment != null;
                                  
                                  return _buildActionCardContent(
                                    isRefinedView ? tr.translate('treatment_adjustment_label') : tr.translate('ai_recommendation'), 
                                    isRefinedView 
                                      ? adjustment
                                      : (adjustment != null 
                                          ? _deduplicateTreatment(summary, adjustment)
                                          : summary), 
                                    isRefinedView ? Icons.auto_awesome : Icons.psychology_outlined,
                                    isRefinedView ? Colors.orange : ColorPalette.emeraldGreen,
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScrollablePanel({required String title, required IconData icon, required Widget child}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
            child: Row(
              children: [
                Icon(icon, color: ColorPalette.emeraldGreen, size: 20),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16, color: ColorPalette.textPrimary),
                ),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: child,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUnifiedMetricsCard(dynamic tr) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            tr.translate('analysis_metrics').toUpperCase(),
            style: GoogleFonts.outfit(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: ColorPalette.textPrimary,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 16),
          // Single Row: All Analysis Metrics (AI + Env)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildGauge(
                tr.translate('confidence'), 
                "${(record.confidence * 100).toInt()}%", 
                Icons.psychology_outlined, 
                record.confidence, 
                ColorPalette.emeraldGreen, 
                isCompact: true,
              ),
              _buildGauge(
                tr.translate('severity'), 
                tr.translate(record.severity?.toLowerCase() == 'low' ? 'severity_low' : (record.severity?.toLowerCase() == 'high' ? 'severity_high' : 'severity_medium')), 
                Icons.warning_amber_rounded, 
                record.severity?.toLowerCase() == 'low' ? 0.3 : (record.severity?.toLowerCase() == 'high' ? 0.9 : 0.6), 
                record.severity?.toLowerCase() == 'low' ? ColorPalette.emeraldGreen : (record.severity?.toLowerCase() == 'high' ? ColorPalette.rustRed : Colors.orange), 
                isCompact: true,
              ),
              _buildGauge(tr.translate('temp'), "${record.temperature ?? 23.9}°C", Icons.thermostat_rounded, 0.6, Colors.orange, isCompact: true),
              _buildGauge(tr.translate('humidity'), "${record.humidity ?? 73.0}%", Icons.water_drop_rounded, 0.73, Colors.blue, isCompact: true),
              _buildGauge(tr.translate('moisture'), "45%", Icons.waves_rounded, 0.45, ColorPalette.emeraldGreen, isCompact: true),
            ],
          ),
        ],
      ),
    );
  }


  Widget _buildGauge(String label, String value, IconData icon, double progress, Color color, {bool isCompact = false}) {
    final double size = isCompact ? 40 : 64;
    return Column(
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            SizedBox(
              width: size,
              height: size,
              child: CircularProgressIndicator(
                value: progress,
                strokeWidth: isCompact ? 4 : 8,
                backgroundColor: Colors.grey.shade100,
                valueColor: AlwaysStoppedAnimation<Color>(color),
              ),
            ),
            Icon(icon, color: color, size: isCompact ? 24 : 30),
          ],
        ),
        const SizedBox(height: 6),
        Text(value, style: GoogleFonts.outfit(fontSize: isCompact ? 14 : 18, fontWeight: FontWeight.bold)),
        Text(label, style: GoogleFonts.outfit(fontSize: 10, color: ColorPalette.textPrimary)),
      ],
    );
  }

  Widget _buildFindingsCard(String farmerInput, dynamic tr, {List<dynamic>? thread, String? reasoning}) {
    return _buildScrollablePanel(
      title: tr.translate('findings'),
      icon: Icons.verified_user_outlined,
      child: _buildFindingsCardContent(farmerInput, tr, thread: thread, reasoning: reasoning),
    );
  }

  Widget _buildFindingsCardContent(String farmerInput, dynamic tr, {List<dynamic>? thread, String? reasoning}) {
    // ═══════════════════════════════════════════════════════════════════════════
    // THREAD EXTRACTION: Build a complete list of all conversation items
    // ═══════════════════════════════════════════════════════════════════════════
    // This replaces the old "first + last only" logic that was hiding intermediate feedbacks.
    // Now we iterate through ALL thread items to display the complete conversation history.
    
    List<Map<String, dynamic>> threadItems = [];
    
    if (thread != null && thread.isNotEmpty) {
      // PRIMARY PATH: Extract from saved conversation thread
      // The thread contains the complete conversation history with all user feedbacks and AI responses
      for (int i = 0; i < thread.length; i++) {
        final item = thread[i];
        
        // Handle both ThreadItem objects and raw Map structures for backward compatibility
        final role = (item is ThreadItem ? item.role : (item as dynamic)['role'])?.toString().toLowerCase() ?? "";
        final content = item is ThreadItem ? item.content : (item as dynamic)['content']?.toString() ?? "";
        
        // Filter valid conversation items (user/farmer inputs and AI/assistant responses)
        if (content.isNotEmpty && (role == 'user' || role == 'farmer' || role == 'ai' || role == 'assistant')) {
          threadItems.add({
            'role': role,
            'content': content,
            'index': i,
          });
        }
      }
    } else {
      // FALLBACK PATH: Reconstruct thread from legacy record fields
      // For older records that don't have the thread field, we build it from individual fields
      
      // Step 1: Initial user input
      if (record.farmerInput != null && record.farmerInput!.isNotEmpty) {
        threadItems.add({'role': 'user', 'content': record.farmerInput!, 'index': 0});
      }
      
      // Step 2: Initial AI diagnosis
      if (record.treatmentSummary.isNotEmpty) {
        threadItems.add({'role': 'ai', 'content': record.treatmentSummary, 'index': 1});
      }
      
      // Step 3 & 4: Refinement (if available)
      if (record.refinementReasoning != null && record.refinementReasoning!.isNotEmpty) {
        // Note: We don't have the actual refinement input saved in legacy records,
        // so we use a placeholder. The reasoning/adjustment is the important part.
        threadItems.add({'role': 'user', 'content': 'Additional feedback provided', 'index': 2});
        threadItems.add({'role': 'ai', 'content': reasoning ?? record.refinementReasoning!, 'index': 3});
      }
    }


    // ═══════════════════════════════════════════════════════════════════════════
    // DYNAMIC DISPLAY: Render all thread items with appropriate styling
    // ═══════════════════════════════════════════════════════════════════════════
    // Each item gets numbered labels (e.g., "Refinement Feedback #2", "#3", etc.)
    // AI responses are clickable to switch between treatment views
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Iterate through ALL thread items (no more skipping intermediate feedbacks!)
        ...threadItems.asMap().entries.map((entry) {
          final index = entry.key;
          final item = entry.value;
          final role = item['role'] as String;
          final content = item['content'] as String;
          final isUser = role == 'user' || role == 'farmer';
          
          // Determine label, icon, and color based on role and position
          String label;
          IconData icon;
          Color color;
          Widget? itemWidget;
          
          if (isUser) {
            // USER/FARMER FEEDBACK
            if (index == 0) {
              // First user message: "Initial Request"
              label = tr.translate('initial_request');
              icon = Icons.person_outline;
              color = Colors.grey.shade600;
            } else {
              // Subsequent user messages: "Refinement Feedback #2", "#3", etc.
              final feedbackNumber = (index ~/ 2) + 1;
              label = '${tr.translate('refinement_feedback')} #$feedbackNumber';
              icon = Icons.edit_note;
              color = Colors.blue.shade600;
            }
            
            // Render as a simple text box
            itemWidget = _buildFindingStep(
              label: label,
              text: content,
              icon: icon,
              color: color,
            );
          } else {
            // AI RESPONSE (clickable to switch treatment views)
            if (index == 1) {
              // First AI response: "Initial Diagnosis"
              label = tr.translate('initial_diagnosis');
              icon = Icons.auto_awesome;
              color = ColorPalette.emeraldGreen;
              
              itemWidget = Consumer(
                builder: (context, ref, _) {
                  final activeView = ref.watch(activeDiagnosisViewProvider);
                  return _buildClickableFindingCard(
                    label: label,
                    text: tr.translate('view_standard_treatment'),
                    icon: icon,
                    color: color,
                    isActive: activeView == 0,
                    onTap: () => ref.read(activeDiagnosisViewProvider.notifier).state = 0,
                  );
                }
              );
            } else {
              // Subsequent AI responses: "Refined Diagnosis #2", "#3", etc.
              final responseNumber = (index ~/ 2);
              label = '${tr.translate('refined_diagnosis')} #$responseNumber';
              icon = Icons.psychology_outlined;
              color = Colors.orange.shade700;
              
              itemWidget = Consumer(
                builder: (context, ref, _) {
                  final activeView = ref.watch(activeDiagnosisViewProvider);
                  return _buildClickableFindingCard(
                    label: label,
                    text: tr.translate('view_adjusted_plan'),
                    icon: icon,
                    color: color,
                    isActive: activeView == responseNumber,
                    onTap: () => ref.read(activeDiagnosisViewProvider.notifier).state = responseNumber,
                  );
                }
              );
            }
          }
          
          // Add appropriate spacing between items
          return Padding(
            padding: EdgeInsets.only(top: index == 0 ? 0 : (isUser ? 24 : 16)),
            child: itemWidget,
          );
        }).toList(),
      ],
    );
  }

  Widget _buildClickableFindingCard({
    required String label,
    required String text,
    required IconData icon,
    required Color color,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isActive ? color.withValues(alpha: 0.08) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isActive ? color.withValues(alpha: 0.3) : Colors.grey.shade100,
            width: isActive ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 16, color: color),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label.toUpperCase(),
                    style: GoogleFonts.outfit(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: color,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    text,
                    style: GoogleFonts.outfit(
                      fontSize: 13,
                      fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
                      color: ColorPalette.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
            if (isActive)
              Icon(Icons.check_circle, size: 16, color: color),
          ],
        ),
      ),
    );
  }

  Widget _buildFindingStep({
    required String label, 
    required String text, 
    required IconData icon, 
    required Color color
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 8),
            Text(
              label.toUpperCase(),
              style: GoogleFonts.outfit(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: color,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withValues(alpha: 0.1)),
          ),
          child: Text(
            text,
            style: GoogleFonts.outfit(
              fontSize: 14,
              color: ColorPalette.textPrimary,
              height: 1.5,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActionCard(String title, String content, IconData icon, Color color, {bool isSecondary = false}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isSecondary ? color.withValues(alpha: 0.2) : Colors.grey.shade100),
        boxShadow: isSecondary ? [
          BoxShadow(
            color: color.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ] : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.outfit(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: isSecondary ? color : ColorPalette.textSecondary,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 16),
          _buildActionCardContent(title, content, icon, color),
        ],
      ),
    );
  }

  Widget _buildActionCardContent(String title, String content, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(width: 16),
          Expanded(
            child: MarkdownBody(
              data: content,
              styleSheet: MarkdownStyleSheet(
                p: GoogleFonts.outfit(
                  fontSize: 14,
                  color: ColorPalette.textPrimary,
                  height: 1.5,
                  fontWeight: FontWeight.w500,
                ),
                strong: const TextStyle(fontWeight: FontWeight.bold),
                listBullet: GoogleFonts.outfit(fontSize: 14, color: color),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEnvironmentCard(double temp, double humidity, dynamic tr) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            tr.translate('environmental_status'),
            style: GoogleFonts.outfit(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade400,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 24),
          _buildEnvMetric(Icons.thermostat_rounded, tr.translate('temperature'), "$temp°C", tr.translate('optimal'), ColorPalette.emeraldGreen, tr),
          const SizedBox(height: 16),
          _buildEnvMetric(Icons.water_drop_rounded, tr.translate('soil_moisture'), "$humidity%", tr.translate('warning'), ColorPalette.rustRed, tr),
        ],
      ),
    );
  }

  Widget _buildEnvMetric(IconData icon, String label, String value, String status, Color statusColor, dynamic tr) {
    return Row(
      children: [
        Icon(icon, color: Colors.orange.shade300, size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.bold),
              ),
              Text(
                label,
                style: GoogleFonts.outfit(fontSize: 10, color: Colors.grey),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: statusColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            status,
            style: GoogleFonts.outfit(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: statusColor,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoChip(IconData icon, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: ColorPalette.emeraldGreen),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            label,
            style: GoogleFonts.outfit(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: ColorPalette.textSecondary,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  String _formatDate(DateTime date, dynamic tr) {
    final months = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"];
    final month = months[date.month - 1].toLowerCase();
    final monthStr = tr.translate(month);
    return "$monthStr ${date.day.toString().padLeft(2, '0')}, ${date.year}";
  }

  Widget _buildLanguageInfo(String languageCode, dynamic tr) {
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

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.language_rounded, size: 16, color: Colors.blue.shade400),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            "${tr.translate('scan_in')} $label",
            style: GoogleFonts.outfit(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: ColorPalette.textSecondary,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildImageHeader(String path, {bool isCompact = false, bool isBoxed = false, required dynamic tr}) {
    return Container(
      height: isBoxed ? 200 : (isCompact ? 180 : 300),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          fit: StackFit.expand,
          children: [
            kIsWeb 
              ? Image.network(
                  path,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => _buildPlaceholder(),
                )
              : Image.file(
                  File(path),
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => _buildPlaceholder(),
                ),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.2),
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.2),
                  ],
                ),
              ),
            ),
            Positioned(
              bottom: isBoxed ? 12 : 16,
              left: isBoxed ? 12 : 16,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: const BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.all(Radius.circular(8)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.photo_library_outlined, color: Colors.white, size: 12),
                    const SizedBox(width: 6),
                    Text(
                      isBoxed ? tr.translate('evidence').toUpperCase() : tr.translate('analyzed_evidence').toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.1,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _deduplicateTreatment(String summary, String? adjustment) {
    if (adjustment == null || adjustment.isEmpty) return summary;
    
    // Check if adjustment is already appended in summary (common in older records)
    // The pattern used was "\n\n[Label]: adjustment"
    // We look for the adjustment string itself at the end of the summary
    if (summary.contains(adjustment)) {
      // Find where the adjustment starts in the summary
      final index = summary.lastIndexOf(adjustment);
      if (index > 0) {
        // Try to strip the label and spacing before it
        // We look backwards for the first '[' before the adjustment
        final labelStart = summary.lastIndexOf('[', index);
        if (labelStart != -1 && labelStart > 2) {
           return summary.substring(0, labelStart).trim();
        }
        return summary.substring(0, index).trim();
      }
    }
    return summary;
  }

  Widget _buildPlaceholder() {
    return Container(
      color: Colors.grey.shade50,
      child: const Center(
        child: Icon(Icons.image_not_supported_outlined, color: Colors.grey, size: 32),
      ),
    );
  }
}
