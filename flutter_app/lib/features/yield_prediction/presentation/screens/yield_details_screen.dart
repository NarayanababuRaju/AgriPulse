import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_app/core/theme/color_palette.dart';
import 'package:flutter_app/features/yield_prediction/models/yield_record.dart';
import 'package:flutter_app/features/yield_prediction/presentation/widgets/yield_details_pane.dart';

class YieldDetailsScreen extends ConsumerWidget {
  final YieldRecord record;

  const YieldDetailsScreen({super.key, required this.record});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    debugPrint("🔍 YieldDetailsScreen: Loading record ${record.id}");
    
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
      body: YieldDetailsPane(record: record),
    );
  }
}
