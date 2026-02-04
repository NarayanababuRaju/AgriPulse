import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_app/core/theme/color_palette.dart';
import 'package:flutter_app/features/crop_diagnosis/models/diagnosis_record.dart';
import 'package:flutter_app/features/crop_diagnosis/presentation/widgets/diagnosis_details_pane.dart';

/// Diagnosis Details Screen
/// 
/// Displays the details of a past diagnosis record.
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
      body: DiagnosisDetailsPane(record: record),
    );
  }
}
