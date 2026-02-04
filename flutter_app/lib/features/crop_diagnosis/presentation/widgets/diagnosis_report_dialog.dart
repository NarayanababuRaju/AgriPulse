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

    // Extract 4-part findings from thread if available
    String? initialInput = farmerDescription;
    String? initialResponse;
    String? refinementInput = additionalDescription;
    String? refinementResponse = reasoning;

    if (thread != null && thread!.isNotEmpty) {
      // Robust extraction for both ThreadItem objects and Map structures
      final userMessages = thread!.where((item) {
        final role = item is ThreadItem ? item.role : (item as dynamic)['role'];
        return role == 'user';
      }).toList();
      
      final aiMessages = thread!.where((item) {
        final role = item is ThreadItem ? item.role : (item as dynamic)['role'];
        return role == 'ai';
      }).toList();

      String getContent(dynamic item) {
        return item is ThreadItem ? item.content : (item as dynamic)['content']?.toString() ?? "";
      }

      if (userMessages.isNotEmpty) initialInput = getContent(userMessages.first);
      if (aiMessages.isNotEmpty) initialResponse = getContent(aiMessages.first);
      if (userMessages.length > 1) refinementInput = getContent(userMessages.last);
      if (aiMessages.length > 1) refinementResponse = getContent(aiMessages.last);
    }

    // Fallback to widget direct parameters/data if thread is missing
    initialInput ??= farmerDescription;
    initialResponse ??= data['treatment_recommendation']?.toString();
    refinementInput ??= additionalDescription;
    refinementResponse ??= data['refinement_reasoning']?.toString();
    
    // Sanity checks for empty strings
    if (initialInput != null && initialInput.isEmpty) initialInput = null;
    if (initialResponse != null && initialResponse.isEmpty) initialResponse = null;
    if (refinementResponse != null && refinementResponse.isEmpty) refinementResponse = null;
    if (refinementInput != null && refinementInput.isEmpty) refinementInput = null;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      backgroundColor: Colors.white,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 500, maxHeight: 700),
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
                  const Text(
                    "Diagnosis Report",
                    style: TextStyle(
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
                      _buildRow("Date:", date),
                      const SizedBox(height: 12),
                      _buildRow("Disease:", disease, isBold: true, color: ColorPalette.rustRed),
                      const SizedBox(height: 12),
                      _buildRow("Confidence:", "${(confidence * 100).toInt()}%"),
                      
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 20),
                        child: Divider(),
                      ),

                      const Text(
                        "DIAGNOSTIC FINDINGS",
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // 1. Initial Input
                      _buildStepBox(
                        label: tr('initial_request'),
                        text: (initialInput == null || initialInput.trim().isEmpty) 
                            ? tr('no_feedback_provided') 
                            : initialInput,
                        icon: Icons.person_outline,
                        color: Colors.grey.shade600,
                      ),
                      
                      // 2. Initial Response
                      if (initialResponse != null) ...[
                        const SizedBox(height: 12),
                        _buildStepBox(
                          label: tr('ai_findings'), // Standardized localized key
                          text: initialResponse,
                          icon: Icons.auto_awesome,
                          color: ColorPalette.emeraldGreen,
                        ),
                      ],

                      // 3. Refinement Input
                      if (refinementInput != null) ...[
                        const SizedBox(height: 12),
                        _buildStepBox(
                          label: tr('refinement_feedback'),
                          text: refinementInput,
                          icon: Icons.edit_note,
                          color: Colors.blue.shade600,
                        ),
                      ],

                      // 4. Refinement Response
                      if (refinementResponse != null) ...[
                        const SizedBox(height: 12),
                        _buildStepBox(
                          label: tr('refinement_reasoning'),
                          text: refinementResponse,
                          icon: Icons.psychology_outlined,
                          color: Colors.orange.shade700,
                        ),
                      ],

                      const SizedBox(height: 32),
                      const Text("Standard Treatment Plan:", style: TextStyle(fontWeight: FontWeight.bold)),
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
                              const Row(
                                children: [
                                  Icon(Icons.auto_awesome, color: Colors.orange, size: 20),
                                  SizedBox(width: 8),
                                  Text(
                                    "Treatment Adjustments",
                                    style: TextStyle(
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
                          const SnackBar(content: Text("Sharing Report..."))
                        );
                      },
                      icon: const Icon(Icons.share_rounded),
                      label: const Text("Share"),
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
                          const SnackBar(content: Text("Downloading PDF..."))
                        );
                      },
                      icon: const Icon(Icons.download_rounded),
                      label: const Text("Download PDF"),
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
