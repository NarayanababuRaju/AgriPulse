import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/theme/color_palette.dart';
import '../../providers/diagnosis_provider.dart';

class DiagnosisReportDialog extends StatelessWidget {
  final Map<String, dynamic> data;
  final String? farmerDescription;

  const DiagnosisReportDialog({
    super.key,
    required this.data,
    this.farmerDescription,
  });

  @override
  Widget build(BuildContext context) {
    // Extract data with fallbacks
    final disease = data['disease_name'] ?? "Unknown Issue";
    final confidence = data['confidence_score'] ?? 0.0;
    final treatment = data['treatment_recommendation'] ?? "No specific treatment available.";
    final date = DateTime.now().toString().split(' ')[0]; // Mock Date

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      backgroundColor: Colors.white,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 500),
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

              // Content
              _buildRow("Date:", date),
              const SizedBox(height: 12),
              _buildRow("Disease:", disease, isBold: true, color: ColorPalette.rustRed),
              const SizedBox(height: 12),
              _buildRow("Confidence:", "${(confidence * 100).toInt()}%"),
              
              if (farmerDescription != null && farmerDescription!.isNotEmpty) ...[
                const SizedBox(height: 12),
                const Text("Farmer Description:", style: TextStyle(color: Colors.grey, fontSize: 13)),
                const SizedBox(height: 4),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Text(
                    farmerDescription!,
                    style: const TextStyle(fontSize: 14, fontStyle: FontStyle.italic),
                  ),
                ),
              ],

              const SizedBox(height: 24),
              const Text("Treatment Plan:", style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text(
                treatment,
                style: const TextStyle(color: ColorPalette.textPrimary, height: 1.5),
              ),

              const SizedBox(height: 32),

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
