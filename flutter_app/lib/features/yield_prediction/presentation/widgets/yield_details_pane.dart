import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_app/core/theme/color_palette.dart';
import 'package:flutter_app/features/yield_prediction/domain/entities/yield_prediction.dart';
import 'package:flutter_app/features/yield_prediction/models/yield_record.dart';
import 'package:flutter_app/features/yield_prediction/presentation/widgets/yield_result_view.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_app/core/localization/language_provider.dart';

class YieldDetailsPane extends ConsumerWidget {
  final YieldRecord record;
  final bool isCompact;

  const YieldDetailsPane({
    super.key, 
    required this.record, 
    this.isCompact = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tr = ref.watch(languageProvider.notifier);
    
    if (record.rawAiResponse.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.history_toggle_off_rounded, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              tr.translate('detailed_data_unavailable'),
              style: GoogleFonts.outfit(fontSize: 16, color: ColorPalette.textSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(tr.translate('run_new_prediction_hint')),
          ],
        ),
      );
    }

    final prediction = YieldPrediction.fromJson(record.id, record.rawAiResponse);

    return Column(
      children: [
        Expanded(
          child: YieldResultView(
            result: prediction,
            cropName: record.cropName,
            fieldArea: 1.0, 
            isCompact: isCompact,
          ),
        ),
      ],
    );
  }

}
