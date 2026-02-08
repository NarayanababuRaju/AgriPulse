import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_app/core/theme/color_palette.dart';
import 'package:flutter_app/features/crop_diagnosis/models/diagnosis_record.dart';
import 'package:flutter_app/features/crop_diagnosis/presentation/widgets/diagnosis_details_pane.dart';
import 'package:flutter_app/features/crop_diagnosis/providers/diagnosis_provider.dart';
import 'package:flutter_app/core/localization/language_provider.dart';
import 'package:flutter_app/core/widgets/language_selector.dart';

/// Diagnosis Details Screen
/// 
/// Displays the details of a past diagnosis record.
class DiagnosisDetailsScreen extends ConsumerWidget {
  final DiagnosisRecord record;

  const DiagnosisDetailsScreen({super.key, required this.record});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tr = ref.watch(languageProvider.notifier).translate;

    return Scaffold(
      backgroundColor: ColorPalette.offWhite,
      appBar: AppBar(
        title: Text(
          tr('diagnosis_details'),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
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
                // Load record into controller and trigger translation
                final controller = ref.read(diagnosisProvider.notifier);
                
                // If not already loaded, load it
                if (ref.read(diagnosisProvider).activeRecordId != record.id) {
                   controller.loadRecord(record);
                }
                
                controller.translateDiagnosis(lang.backendName);
              },
            ),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: DiagnosisDetailsPane(record: record),
    );
  }
}
