import 'dart:io';
import 'package:flutter/foundation.dart'; // For kIsWeb
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_app/core/theme/color_palette.dart';
import 'package:flutter_app/features/crop_diagnosis/models/diagnosis_record.dart';

/// Diagnosis Details Screen
/// 
/// Displays the details of a past diagnosis record.
/// This includes the image, disease name, confidence score, and treatment advice.
class DiagnosisDetailsScreen extends ConsumerWidget {
  final DiagnosisRecord record;

  const DiagnosisDetailsScreen({super.key, required this.record});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: ColorPalette.offWhite,
      appBar: AppBar(
        title: const Text("Diagnosis Details"),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 1. Image Preview
            Container(
              height: 300,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: _buildImage(record.imagePath),
              ),
            ),
            
            const SizedBox(height: 24),

            // 2. Diagnosis Result
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header: Disease Name - Context-aware for healthy plants
                  Builder(
                    builder: (context) {
                      final String diseaseName = record.diseaseName.toLowerCase();
                      final bool isHealthy = diseaseName.contains('healthy') || 
                                             diseaseName.contains('no visible disease') ||
                                             diseaseName.contains('no disease');
                      
                      final Color statusColor = isHealthy ? ColorPalette.emeraldGreen : ColorPalette.rustRed;
                      final IconData statusIcon = isHealthy ? Icons.check_circle_outline_rounded : Icons.warning_amber_rounded;
                      final String statusLabel = isHealthy ? "Healthy Plant" : "Detected Issue";
                      
                      return Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: statusColor.withValues(alpha: 0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(statusIcon, color: statusColor, size: 32),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  statusLabel,
                                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                                ),
                                Text(
                                  record.diseaseName,
                                  style: TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: statusColor,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _formatDate(record.timestamp),
                                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                                ),
                              ],
                            ),
                          ),
                          // Confidence Badge
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.green.shade50,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: Colors.green.shade200),
                            ),
                            child: Text(
                              "${(record.confidence * 100).toInt()}% Confidence",
                              style: TextStyle(
                                color: Colors.green.shade700,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),

                  // Farmer Input Section
                  if (record.farmerInput != null) ...[
                    const Divider(height: 32),
                    const Text(
                      "Farmer's Observation",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: ColorPalette.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.blue.shade100),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.mic, color: Colors.blue, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              record.farmerInput!,
                              style: const TextStyle(
                                fontStyle: FontStyle.italic,
                                color: ColorPalette.textPrimary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  // AI Reasoning Section
                  if (record.refinementReasoning != null) ...[
                    const Divider(height: 32),
                     const Text(
                      "AI Reasoning",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: ColorPalette.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.purple.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.purple.shade100),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.psychology, color: Colors.purple.shade400, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              record.refinementReasoning!,
                              style: TextStyle(color: Colors.purple.shade900),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  
                  const Divider(height: 48),

                  // Treatment Section
                  const Text(
                    "Recommended Treatment",
                    style: TextStyle(
                      fontSize: 18, 
                      fontWeight: FontWeight.bold,
                      color: ColorPalette.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: ColorPalette.offWhite,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Column(
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                             const Icon(Icons.medical_services_outlined, color: ColorPalette.emeraldGreen, size: 24),
                             const SizedBox(width: 16),
                             Expanded(
                               child: Text(
                                 record.treatmentSummary,
                                 style: const TextStyle(
                                   fontSize: 16,
                                   height: 1.5,
                                   color: ColorPalette.textPrimary,
                                 ),
                               ),
                             ),
                          ],
                        ),
                        if (record.treatmentAdjustment != null) ...[
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.orange.shade50,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.orange.shade200),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.info_outline, size: 16, color: Colors.orange.shade800),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    "Adjustment: ${record.treatmentAdjustment}",
                                    style: TextStyle(
                                      fontSize: 12, 
                                      color: Colors.orange.shade900,
                                      fontStyle: FontStyle.italic
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          )
                        ]
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImage(String path) {
    if (path.startsWith('http')) {
      return Image.network(path, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const Icon(Icons.broken_image));
    }
    if (path.startsWith('assets/')) {
      return Image.asset(path, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const Icon(Icons.broken_image));
    }
    if (kIsWeb) {
      return Image.network(
         (path.startsWith('http') || path.startsWith('blob:')) ? path : "assets/images/logo.png", // Fallback
         fit: BoxFit.cover, 
         errorBuilder: (_, __, ___) => const Icon(Icons.broken_image)
      );
    }
    return Image.file(File(path), fit: BoxFit.cover, errorBuilder: (_, __, ___) => const Icon(Icons.broken_image));
  }

  String _formatDate(DateTime date) {
    return "${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}";
  }
}
