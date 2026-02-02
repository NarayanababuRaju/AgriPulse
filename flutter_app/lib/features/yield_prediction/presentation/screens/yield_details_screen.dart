import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_app/core/theme/color_palette.dart';
import 'package:flutter_app/features/yield_prediction/domain/entities/yield_prediction.dart';
import 'package:flutter_app/features/yield_prediction/models/yield_record.dart';
import 'package:flutter_app/features/yield_prediction/presentation/widgets/yield_result_view.dart';

class YieldDetailsScreen extends ConsumerWidget {
  final YieldRecord record;

  const YieldDetailsScreen({super.key, required this.record});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    debugPrint("🔍 YieldDetailsScreen: Loading record ${record.id}");
    
    if (record.rawAiResponse.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text("Prediction Results")),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.history_toggle_off_rounded, size: 64, color: Colors.grey),
              const SizedBox(height: 16),
              Text(
                "Detailed data unavailable for this historical record.",
                style: GoogleFonts.outfit(fontSize: 16, color: ColorPalette.textSecondary),
              ),
              const SizedBox(height: 8),
              const Text("Please run a new prediction to see full details."),
            ],
          ),
        ),
      );
    }

    final prediction = YieldPrediction.fromJson(record.id, record.rawAiResponse);

    return Scaffold(
      backgroundColor: ColorPalette.offWhite,
      appBar: AppBar(
        title: Text(
          "Historical Prediction",
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: ColorPalette.textPrimary,
      ),
      body: Column(
        children: [
          _buildInfoBar(record),
          Expanded(
            child: YieldResultView(
              result: prediction,
              cropName: record.cropName,
              fieldArea: 1.0, // Should ideally be saved in YieldRecord too, defaulting to 1 for now
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoBar(YieldRecord record) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      color: Colors.white,
      child: Row(
        children: [
          const Icon(Icons.grass, color: ColorPalette.emeraldGreen, size: 16),
          const SizedBox(width: 8),
          Text(
            record.cropName,
            style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: ColorPalette.textPrimary),
          ),
          const SizedBox(width: 16),
          const Icon(Icons.calendar_today_rounded, color: Colors.grey, size: 14),
          const SizedBox(width: 4),
          Text(
            _formatDate(record.timestamp),
            style: GoogleFonts.outfit(fontSize: 12, color: ColorPalette.textSecondary),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return "${date.day}/${date.month}/${date.year}";
  }
}
