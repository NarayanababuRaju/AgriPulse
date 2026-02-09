import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_app/core/theme/color_palette.dart';
import 'package:flutter_app/features/yield_prediction/presentation/widgets/mini_forecast_widget.dart';

class DiagnosisHeaderCard extends ConsumerWidget {
  const DiagnosisHeaderCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < 600;

        return Container(
          margin: const EdgeInsets.fromLTRB(24, 24, 24, 16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
            border: Border.all(color: Colors.grey.shade100),
          ),
          child: Row(
            children: [
              // Branding
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: ColorPalette.rustRed, // Different color for Diagnosis
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.local_hospital_rounded, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      "AgriPulse AI",
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.outfit(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: ColorPalette.textPrimary,
                      ),
                    ),
                    Text(
                      "CROP DOCTOR ENGINE",
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.outfit(
                        fontSize: 9,
                        letterSpacing: 1.0,
                        fontWeight: FontWeight.w600,
                        color: ColorPalette.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              
              if (!isCompact) ...[
                const SizedBox(width: 24),
                // Weather Forecast (Mini)
                const MiniForecastWidget(),
              ],
              
              const Spacer(),
            ],
          ),
        );
      },
    );
  }
}
