import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_app/core/theme/color_palette.dart';
import 'package:flutter_app/features/yield_prediction/presentation/widgets/mini_forecast_widget.dart';
import 'package:flutter_app/features/yield_prediction/providers/language_provider.dart';

class YieldHeaderCard extends ConsumerWidget {
  const YieldHeaderCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      margin: const EdgeInsets.fromLTRB(24, 24, 24, 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.05),
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
              color: ColorPalette.emeraldGreen,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.grass_rounded, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "AgriPulse AI",
                style: GoogleFonts.outfit(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: ColorPalette.textPrimary,
                ),
              ),
              Text(
                "YIELD PREDICTOR ENGINE",
                style: GoogleFonts.outfit(
                  fontSize: 9,
                  letterSpacing: 1.0,
                  fontWeight: FontWeight.w600,
                  color: ColorPalette.textSecondary,
                ),
              ),
            ],
          ),
          
          const SizedBox(width: 24),
          
          // Weather Forecast (Mini)
          const MiniForecastWidget(),
          
          const Spacer(),
          
          // Language Dropdown
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: ColorPalette.offWhite,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<AppLanguage>(
                value: ref.watch(languageProvider),
                icon: const Icon(Icons.language, size: 18, color: ColorPalette.emeraldGreen),
                isDense: true,
                style: GoogleFonts.outfit(
                  fontSize: 13, 
                  fontWeight: FontWeight.w600, 
                  color: ColorPalette.textPrimary
                ),
                onChanged: (lang) {
                  if (lang != null) {
                    ref.read(languageProvider.notifier).setLanguage(lang);
                  }
                },
                 items: AppLanguage.values.map((lang) {
                  return DropdownMenuItem(
                    value: lang,
                    child: Text(
                      lang == AppLanguage.en ? "English" : 
                      lang == AppLanguage.hi ? "हिन्दी" :
                      lang == AppLanguage.ta ? "தமிழ்" :
                      lang == AppLanguage.kn ? "ಕನ್ನಡ" :
                      lang == AppLanguage.te ? "తెలుగు" : "മലയാളം",
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
