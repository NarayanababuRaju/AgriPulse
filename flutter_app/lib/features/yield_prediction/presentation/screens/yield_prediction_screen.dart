import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';


import 'package:flutter_app/core/theme/color_palette.dart';
import 'package:flutter_app/features/yield_prediction/providers/yield_provider.dart';
import 'package:flutter_app/core/localization/language_provider.dart';
import 'package:flutter_app/features/yield_prediction/presentation/widgets/yield_header_card.dart';
import 'package:flutter_app/core/widgets/language_selector.dart';
import 'package:flutter_app/features/yield_prediction/presentation/widgets/yield_result_view.dart';

class YieldPredictionScreen extends ConsumerStatefulWidget {
  const YieldPredictionScreen({super.key});

  @override
  ConsumerState<YieldPredictionScreen> createState() => _YieldPredictionScreenState();
}

class _YieldPredictionScreenState extends ConsumerState<YieldPredictionScreen> {
  static const List<String> _crops = ['Onion', 'Tomato', 'Potato', 'Rice', 'Wheat', 'Maize', 'Cotton', 'Sugarcane'];
  // static const List<double> _areas = [0.5, 1.0, 1.25, 1.5, 1.75, 2.0, 2.25, 2.5, 2.75, 3.0, 3.25, 3.5, 3.75, 4.0, 4.25, 4.5, 4.75, 5.0, 6.0, 7.0, 8.0, 9.0, 10.0, 20.0, 50.0];
  static const List<String> _soils = ['Clay Loam', 'Sandy Loam', 'Silt Loam', 'Peat', 'Chalky', 'Black Soil', 'Red Soil'];

  @override
  Widget build(BuildContext context) {
    // Watch language state to trigger rebuilds on language change
    ref.watch(languageProvider);
    
    final yieldState = ref.watch(yieldProvider);
    final yieldNotifier = ref.read(yieldProvider.notifier);
    final languageNotifier = ref.read(languageProvider.notifier);

    // Listen for errors
    ref.listen(yieldProvider, (previous, next) {
      if (next.errorMessage != null && next.errorMessage != previous?.errorMessage) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.errorMessage!),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    });
    
    ref.listen(languageProvider, (previous, next) {
      if (previous != next && yieldState.result != null) {
        yieldNotifier.translateResult(next.backendName);
      }
    });

    return Scaffold(
      backgroundColor: ColorPalette.offWhite,
      appBar: AppBar(
        title: Text(
          languageNotifier.translate('yield_prediction'),
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
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
          const Center(
            child: LanguageSelector(
              textColor: ColorPalette.textPrimary,
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () {
              yieldNotifier.reset();
            },
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: Column(
        children: [
          // 1. Full-Width Branding Header
          const YieldHeaderCard(),
          
          // 2. Main Area (Modular Split View)
          Expanded(
            child: _buildMainArea(yieldState, yieldNotifier, languageNotifier, context),
          ),
        ],
      ),
    );
  }

  Widget _buildMainArea(
    YieldState yieldState,
    YieldController yieldNotifier,
    dynamic languageNotifier,
    BuildContext context,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. LEFT COLUMN: Input Cockpit
        _buildInputColumn(yieldState, yieldNotifier, languageNotifier, context),

        // 2. RIGHT COLUMN: Prediction Result
        _buildResultColumn(yieldState, languageNotifier),
      ],
    );
  }

  Widget _buildInputColumn(
    YieldState yieldState,
    YieldController yieldNotifier,
    dynamic languageNotifier,
    BuildContext context,
  ) {
    return Expanded(
      flex: 4,
      child: Container(
        color: ColorPalette.offWhite,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.layers_outlined, size: 16, color: ColorPalette.textPrimary),
                        const SizedBox(width: 8),
                        Text(
                          languageNotifier.translate('field_parameters').toUpperCase(),
                          style: GoogleFonts.outfit(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: ColorPalette.textPrimary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    
                    _buildParameterSelectionRows(yieldState, yieldNotifier, languageNotifier),
                    
                    if (yieldState.expectedHarvestDate != null && 
                        yieldState.expectedHarvestDate!.difference(DateTime.now()).inDays > 14)
                      _buildHarvestWarning(languageNotifier),
                      
                    const SizedBox(height: 32),
                    _buildPredictionButton(yieldState, yieldNotifier, languageNotifier, context),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
            _buildSystemHealthCard(languageNotifier),
          ],
        ),
      ),
    );
  }

  Widget _buildResultColumn(YieldState yieldState, dynamic languageNotifier) {
    return Expanded(
      flex: 8,
      child: Container(
        color: Colors.white,
        child: yieldState.isLoading
            ? _buildLoadingState()
            : yieldState.errorMessage != null
                ? _buildErrorState(yieldState.errorMessage!)
                : yieldState.result != null
                    ? YieldResultView(
                        result: yieldState.result!,
                        cropName: yieldState.cropName!,
                        fieldArea: yieldState.fieldArea!,
                      )
                    : _buildResultPlaceholder(),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(color: ColorPalette.emeraldGreen),
          const SizedBox(height: 24),
          Text(
            "Gemini is analyzing climate\nand soil factors...",
            textAlign: TextAlign.center,
            style: GoogleFonts.outfit(
              fontSize: 18,
              color: ColorPalette.textSecondary,
            ),
          ),
        ],
      ).animate().fadeIn(),
    );
  }

  Widget _buildErrorState(String error) {
    final languageNotifier = ref.read(languageProvider.notifier);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline_rounded, color: Colors.orange, size: 64),
            const SizedBox(height: 16),
            Text(
              languageNotifier.translate('prediction_failed'),
              style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold, color: ColorPalette.textPrimary),
            ),
            const SizedBox(height: 8),
            Text(
              error,
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(fontSize: 14, color: ColorPalette.textSecondary),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => ref.read(yieldProvider.notifier).predictYield(),
              style: ElevatedButton.styleFrom(
                backgroundColor: ColorPalette.emeraldGreen,
                foregroundColor: Colors.white,
              ),
              child: Text(languageNotifier.translate('retry')),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultPlaceholder() {
    String tr(String key) => ref.read(languageProvider.notifier).translate(key);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(48),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 80),
          Icon(
            Icons.auto_awesome_rounded,
            size: 80,
            color: ColorPalette.emeraldGreen.withValues(alpha: 0.1),
          ).animate(onPlay: (controller) => controller.repeat())
           .shimmer(duration: 2000.ms, color: ColorPalette.mintGreen.withValues(alpha: 0.2)),
          const SizedBox(height: 32),
          Text(
            tr('climate_aware_forecasting'),
            textAlign: TextAlign.center,
            style: GoogleFonts.outfit(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: ColorPalette.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            "${tr('ai_engine_reasoning')}\n\n• ${tr('reasoning_factor_1')}\n• ${tr('reasoning_factor_2')}\n• ${tr('reasoning_factor_3')}\n• ${tr('reasoning_factor_4')}",
            textAlign: TextAlign.center,
            style: GoogleFonts.outfit(
              fontSize: 15,
              color: ColorPalette.textSecondary,
              height: 1.6,
            ),
          ),
           const SizedBox(height: 48),
           Container(
             padding: const EdgeInsets.all(20),
             decoration: BoxDecoration(
               color: ColorPalette.offWhite,
               borderRadius: BorderRadius.circular(16),
               border: Border.all(color: Colors.grey.shade200),
             ),
             // Info Bar
             child: Row(
               children: [
                 const Icon(Icons.info_outline_rounded, color: ColorPalette.emeraldGreen),
                 const SizedBox(width: 16),
                 Expanded(
                   child: Text(
                     "Your data helps us build a more resilient agricultural future for the community.",
                     style: GoogleFonts.outfit(fontSize: 13, color: ColorPalette.textSecondary),
                   ),
                 ),
               ],
             ),
           ),
        ],
      ),
    );
  }

  // Removed redundant _buildResultContent and sub-methods as they are now in YieldResultView


  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0, left: 4.0),
      child: Text(
        text,
        style: GoogleFonts.outfit(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: ColorPalette.textSecondary,
        ),
      ),
    );
  }

  Widget _buildSelectionChips<T>({
    required List<T> items,
    required T? selectedValue,
    required Function(T) onSelected,
    required String Function(T) itemLabelMapper,
  }) {
    return Wrap(
      spacing: 12,
      runSpacing: 10,
      children: items.map((item) {
        final isSelected = item == selectedValue;
        return _buildChoiceChip(
          label: itemLabelMapper(item),
          isSelected: isSelected,
          onSelected: (val) {
            if (val) onSelected(item);
          },
        );
      }).toList(),
    );
  }

  Widget _buildChoiceChip({
    required String label, 
    required bool isSelected, 
    required Function(bool) onSelected,
  }) {
    return ChoiceChip(
      label: Text(
        label,
        style: GoogleFonts.outfit(
          fontSize: 11,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
          color: isSelected ? Colors.white : ColorPalette.textPrimary,
        ),
      ),
      selected: isSelected,
      onSelected: onSelected,
      selectedColor: ColorPalette.emeraldGreen,
      backgroundColor: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(
          color: isSelected ? ColorPalette.emeraldGreen : Colors.grey.shade200,
          width: 1,
        ),
      ),
      showCheckmark: false,
    );
  }

  Widget _buildDatePicker({
    required DateTime? selectedDate,
    required Function(DateTime) onChanged,
    IconData? icon,
  }) {
    return InkWell(
      onTap: () async {
        final DateTime? picked = await showDatePicker(
          context: context,
          initialDate: selectedDate ?? DateTime.now(),
          firstDate: DateTime(2020),
          lastDate: DateTime(2030),
        );
        if (picked != null) onChanged(picked);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFFF1F4F8),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(icon ?? Icons.calendar_today_rounded, size: 18, color: ColorPalette.textSecondary.withValues(alpha: 0.6)),
            const SizedBox(width: 12),
            Text(
              selectedDate != null ? DateFormat('MM/dd/yyyy').format(selectedDate) : "MM/DD/YYYY",
              style: GoogleFonts.outfit(
                color: selectedDate != null ? ColorPalette.textPrimary : ColorPalette.textSecondary.withValues(alpha: 0.4),
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }


  Widget _buildHarvestWarning(dynamic languageNotifier) {
    return Padding(
      padding: const EdgeInsets.only(top: 12.0),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF9C4),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFFFBC02D).withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            const Icon(Icons.wb_sunny_outlined, size: 16, color: Color(0xFFF57F17)),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                languageNotifier.translate('harvest_window_warning'),
                style: GoogleFonts.outfit(
                  fontSize: 11,
                  color: const Color(0xFFF57F17),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ).animate().fadeIn().slideY(begin: 0.1, end: 0),
    );
  }

  Widget _buildPredictionButton(
    YieldState yieldState,
    YieldController yieldNotifier,
    dynamic languageNotifier,
    BuildContext context,
  ) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: yieldState.isLoading ? null : () {
          if (yieldState.cropName == null) {
            _showWarning(context, languageNotifier.translate('select_crop_warning'));
            return;
          }
          if (yieldState.fieldArea == null) {
            _showWarning(context, languageNotifier.translate('select_area_warning'));
            return;
          }
          if (yieldState.soilType == null) {
            _showWarning(context, languageNotifier.translate('select_soil_warning'));
            return;
          }
          if (yieldState.expectedHarvestDate == null) {
            _showWarning(context, languageNotifier.translate('select_harvest_date'));
            return;
          }
          yieldNotifier.predictYield();
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: ColorPalette.emeraldGreen,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 0,
        ),
        child: yieldState.isLoading
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.auto_awesome_rounded, size: 18),
                  const SizedBox(width: 10),
                  Text(
                    languageNotifier.translate('run_prediction'),
                    style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
      ),
    );
  }

  void _showWarning(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.orange,
      ),
    );
  }

  Widget _buildSystemHealthCard(dynamic languageNotifier) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF033E33),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.verified_outlined, color: Colors.white, size: 18),
                const SizedBox(width: 8),
                Text(
                  languageNotifier.translate('system_health'),
                  style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              "Gemini 3.0 Pro is monitoring real-time weather and satellite data.",
              style: GoogleFonts.outfit(color: Colors.white.withValues(alpha: 0.6), fontSize: 10, height: 1.4),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                      color: Color(0xFF4CAF50),
                      shape: BoxShape.circle,
                    ),
                  ).animate(onPlay: (c) => c.repeat()).scale(
                        duration: 1000.ms,
                        begin: const Offset(1, 1),
                        end: const Offset(1.5, 1.5),
                      ).fadeOut(),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      "${languageNotifier.translate('active_feed')} ${languageNotifier.translate('api_stable')}",
                      style: GoogleFonts.outfit(
                        color: Colors.white.withValues(alpha: 0.8),
                        fontSize: 8,
                        fontWeight: FontWeight.bold,
                      ),
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

  Widget _buildParameterSelectionRows(
    YieldState yieldState,
    YieldController yieldNotifier,
    dynamic languageNotifier,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Row 1: Crop Name
        _buildLabel(languageNotifier.translate('crop_name')),
        _buildSelectionChips<String>(
          items: _crops,
          selectedValue: yieldState.cropName,
          onSelected: (val) => yieldNotifier.updateCropName(val),
          itemLabelMapper: (val) => languageNotifier.translate(val.toLowerCase()),
        ),
        const SizedBox(height: 24),

        // Row 2: Field Area (Ranges)
        _buildLabel(languageNotifier.translate('field_area')),
        _buildSelectionChips<double>(
          items: [0.5, 1.5, 3.5, 10.0],
          selectedValue: yieldState.fieldArea,
          onSelected: (val) => yieldNotifier.updateFieldArea(val),
          itemLabelMapper: (val) {
            if (val == 0.5) return "< 1 ${languageNotifier.translate('acres')}";
            if (val == 1.5) return "1-2 ${languageNotifier.translate('acres')}";
            if (val == 3.5) return "2-5 ${languageNotifier.translate('acres')}";
            return "> 5 ${languageNotifier.translate('acres')}";
          },
        ),
        const SizedBox(height: 24),

        // Row 3: Soil Type
        _buildLabel(languageNotifier.translate('soil_type')),
        _buildSelectionChips<String>(
          items: _soils,
          selectedValue: yieldState.soilType,
          onSelected: (val) => yieldNotifier.updateSoilType(val),
          itemLabelMapper: (val) => languageNotifier.translate(val.toLowerCase().replaceAll(' ', '_')),
        ),
        const SizedBox(height: 24),

        // Row 4: Dates
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildLabel(languageNotifier.translate('planted_date')),
                  _buildDatePicker(
                    selectedDate: yieldState.plantedDate,
                    onChanged: yieldNotifier.updatePlantedDate,
                    icon: Icons.calendar_today_rounded,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildLabel(languageNotifier.translate('expected_harvest_date')),
                  _buildDatePicker(
                    selectedDate: yieldState.expectedHarvestDate,
                    onChanged: yieldNotifier.updateExpectedHarvestDate,
                    icon: Icons.calendar_today_rounded,
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}
