import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/color_palette.dart';
import '../../../../core/localization/language_provider.dart';
import '../../models/thread_item.dart';

class DiagnosisReportDialog extends ConsumerWidget {
  final Map<String, dynamic> data;
  final String? farmerDescription;
  final String? additionalDescription; // For refinement feedback
  final String? treatmentAdjustment;
  final List<dynamic>? thread;

  const DiagnosisReportDialog({
    super.key,
    required this.data,
    this.farmerDescription,
    this.additionalDescription,
    this.treatmentAdjustment,
    this.thread,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tr = ref.watch(languageProvider.notifier).translate;
    // Extract data with fallbacks
    final disease = data['disease_name']?.toString() ?? "Unknown Issue";
    final confidence = (data['confidence_score'] is num) ? data['confidence_score'] : 0.0;
    final initialTreatment = data['treatment_recommendation']?.toString() ?? "No specific treatment available.";
    
    // Check if we have an adjustment stored in data if not provided explicitly
    final adjustment = treatmentAdjustment ?? data['treatment_adjustment']?.toString();
    final reasoning = data['refinement_reasoning']?.toString();
    final date = DateTime.now().toString().split(' ')[0]; // Mock Date

    // ═══════════════════════════════════════════════════════════════════════════
    // THREAD EXTRACTION: Build a complete list of all conversation items
    // ═══════════════════════════════════════════════════════════════════════════
    // This replaces the old "first + last only" logic that was hiding intermediate feedbacks.
    // Now we iterate through ALL thread items to display the complete conversation history.
    
    List<Map<String, dynamic>> threadItems = [];
    
    if (thread != null && thread!.isNotEmpty) {
      // PRIMARY PATH: Extract from saved conversation thread
      // The thread contains the complete conversation history with all user feedbacks and AI responses
      for (int i = 0; i < thread!.length; i++) {
        final item = thread![i];
        
        // Handle both ThreadItem objects and raw Map structures for backward compatibility
        final role = item is ThreadItem ? item.role : (item as dynamic)['role'];
        final content = item is ThreadItem ? item.content : (item as dynamic)['content']?.toString() ?? "";
        
        // Only include non-empty content
        if (content.isNotEmpty) {
          threadItems.add({
            'role': role,
            'content': content,
            'index': i,
          });
        }
      }
    } else {
      // FALLBACK PATH: Reconstruct thread from legacy dialog parameters
      // For older records or direct dialog invocations without a thread
      
      // Step 1: Initial user input
      if (farmerDescription != null && farmerDescription!.isNotEmpty) {
        threadItems.add({'role': 'user', 'content': farmerDescription, 'index': 0});
      }
      
      // Step 2: Initial AI diagnosis
      if (initialTreatment.isNotEmpty) {
        threadItems.add({'role': 'ai', 'content': initialTreatment, 'index': 1});
      }
      
      // Step 3 & 4: Refinement (if available)
      if (additionalDescription != null && additionalDescription!.isNotEmpty) {
        threadItems.add({'role': 'user', 'content': additionalDescription, 'index': 2});
      }
      if (reasoning != null && reasoning.isNotEmpty) {
        threadItems.add({'role': 'ai', 'content': reasoning, 'index': 3});
      }
    }

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      backgroundColor: Colors.white,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 850, maxHeight: 850),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  const Icon(Icons.description_outlined, color: ColorPalette.emeraldGreen, size: 28),
                  const SizedBox(width: 12),
                  Text(
                    tr('diagnosis_report'),
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: ColorPalette.textPrimary,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const Divider(height: 32),

              // Scrollable Content
              Flexible(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildRow(tr('date_label'), date),
                      const SizedBox(height: 12),
                      _buildRow(tr('disease_label'), disease, isBold: true, color: ColorPalette.rustRed),
                      const SizedBox(height: 12),
                      _buildRow(tr('confidence_label'), "${(confidence * 100).toInt()}%"),
                      
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 20),
                        child: Divider(),
                      ),

                      Text(
                        tr('diagnostic_findings_title'),
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // ═══════════════════════════════════════════════════════════════════════
                      // DYNAMIC DISPLAY: Render all thread items with numbered labels
                      // ═══════════════════════════════════════════════════════════════════════
                      // Each item gets numbered labels (e.g., "Refinement Feedback #2", "#3", etc.)
                      
                      // Iterate through ALL thread items (no more skipping intermediate feedbacks!)
                      ...threadItems.asMap().entries.map((entry) {
                        final index = entry.key;
                        final item = entry.value;
                        final role = item['role'] as String;
                        final content = item['content'] as String;
                        final isUser = role == 'user';
                        
                        // Determine label, icon, and color based on role and position
                        String label;
                        IconData icon;
                        Color color;
                        
                        if (isUser) {
                          // USER FEEDBACK
                          if (index == 0) {
                            // First user message: "Initial Request"
                            label = tr('initial_request');
                            icon = Icons.person_outline;
                            color = Colors.grey.shade600;
                          } else {
                            // Subsequent user messages: "Refinement Feedback #2", "#3", etc.
                            final feedbackNumber = (index ~/ 2) + 1;
                            label = '${tr('refinement_feedback')} #$feedbackNumber';
                            icon = Icons.edit_note;
                            color = Colors.blue.shade600;
                          }
                        } else {
                          // AI RESPONSE
                          if (index == 1) {
                            // First AI response: "AI Findings"
                            label = tr('ai_findings');
                            icon = Icons.auto_awesome;
                            color = ColorPalette.emeraldGreen;
                          } else {
                            // Subsequent AI responses: "Refinement Reasoning #2", "#3", etc.
                            final responseNumber = (index ~/ 2);
                            label = '${tr('refinement_reasoning')} #$responseNumber';
                            icon = Icons.psychology_outlined;
                            color = Colors.orange.shade700;
                          }
                        }
                        
                        // Render each item with appropriate spacing
                        return Padding(
                          padding: EdgeInsets.only(top: index == 0 ? 0 : 12),
                          child: _buildStepBox(
                            label: label,
                            text: content,
                            icon: icon,
                            color: color,
                          ),
                        );
                      }).toList(),

                      const SizedBox(height: 32),
                      Text("${tr('standard_treatment_plan')}:", style: const TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 12),
                      MarkdownBody(
                        data: _deduplicateTreatment(initialTreatment, adjustment),
                        styleSheet: MarkdownStyleSheet(
                          p: const TextStyle(color: ColorPalette.textPrimary, height: 1.5, fontSize: 14),
                          strong: const TextStyle(fontWeight: FontWeight.bold),
                          listBullet: const TextStyle(color: ColorPalette.emeraldGreen),
                        ),
                      ),
                      
                      // Highlighted Adjustments
                      if (adjustment != null && adjustment.isNotEmpty) ...[
                        const SizedBox(height: 24),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.orange.shade50.withValues(alpha: 0.4),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.orange.shade200),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.auto_awesome, color: Colors.orange, size: 20),
                                  const SizedBox(width: 8),
                                  Text(
                                    tr('treatment_adjustments'),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.orange,
                                      fontSize: 15,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              if (reasoning != null) ...[
                                MarkdownBody(
                                  data: reasoning,
                                  styleSheet: MarkdownStyleSheet(
                                    p: TextStyle(
                                      fontSize: 13,
                                      color: Colors.orange.shade900,
                                      fontStyle: FontStyle.italic,
                                    ),
                                    strong: const TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                ),
                                const Divider(height: 24),
                              ],
                              MarkdownBody(
                                data: adjustment,
                                styleSheet: MarkdownStyleSheet(
                                  p: const TextStyle(
                                    color: ColorPalette.textPrimary,
                                    height: 1.5,
                                    fontWeight: FontWeight.w500,
                                    fontSize: 14,
                                  ),
                                  strong: const TextStyle(fontWeight: FontWeight.bold),
                                  listBullet: const TextStyle(color: Colors.orange),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),

              // Actions
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        // Mock Share Action
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(tr('sharing_report')))
                        );
                      },
                      icon: const Icon(Icons.share_rounded),
                      label: Text(tr('share_button')),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        // Mock Download Action
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(tr('downloading_pdf')))
                        );
                      },
                      icon: const Icon(Icons.download_rounded),
                      label: Text(tr('download_pdf_button')),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: ColorPalette.emeraldGreen,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    ).animate().scale(duration: 300.ms, curve: Curves.easeOutBack);
  }

  String _deduplicateTreatment(String summary, String? adjustment) {
    if (adjustment == null || adjustment.isEmpty) return summary;
    if (summary.contains(adjustment)) {
      final index = summary.lastIndexOf(adjustment);
      if (index > 0) {
        final labelStart = summary.lastIndexOf('[', index);
        if (labelStart != -1 && labelStart > 2) {
           return summary.substring(0, labelStart).trim();
        }
        return summary.substring(0, index).trim();
      }
    }
    return summary;
  }

  Widget _buildStepBox({
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
              style: TextStyle(
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
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withValues(alpha: 0.1)),
          ),
          child: MarkdownBody(
            data: text,
            styleSheet: MarkdownStyleSheet(
              p: const TextStyle(
                fontSize: 14,
                color: ColorPalette.textPrimary,
                height: 1.4,
              ),
              strong: const TextStyle(fontWeight: FontWeight.bold),
              listBullet: TextStyle(color: color),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRow(String label, String value, {bool isBold = false, Color? color}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 100,
          child: Text(
            label,
            style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.w500),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              color: color ?? ColorPalette.textPrimary,
              fontSize: 16,
            ),
          ),
        ),
      ],
    );
  }
}
