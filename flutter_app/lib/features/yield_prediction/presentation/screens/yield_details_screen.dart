import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_app/core/theme/color_palette.dart';
import 'package:flutter_app/features/yield_prediction/models/yield_record.dart';
import 'package:flutter_app/features/yield_prediction/presentation/widgets/yield_details_pane.dart';
import 'package:flutter_app/features/yield_prediction/providers/yield_provider.dart';
import 'package:flutter_app/core/localization/language_provider.dart';
import 'package:flutter_app/core/widgets/language_selector.dart';
import 'package:go_router/go_router.dart';

class YieldDetailsScreen extends ConsumerWidget {
  final YieldRecord record;

  const YieldDetailsScreen({super.key, required this.record});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    debugPrint("🔍 YieldDetailsScreen: Loading record ${record.id}");
    
    final tr = ref.watch(languageProvider.notifier).translate;

    return Scaffold(
      backgroundColor: ColorPalette.offWhite,
      appBar: AppBar(
        title: Text(
          tr('yield_prediction'),
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
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
                final controller = ref.read(yieldProvider.notifier);
                
                // If not already loaded, load it
                if (ref.read(yieldProvider).activeRecordId != record.id) {
                   controller.loadRecord(record);
                }
                
                controller.translateResult(lang.backendName);
              },
            ),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: YieldDetailsPane(record: record),
    );
  }
}
