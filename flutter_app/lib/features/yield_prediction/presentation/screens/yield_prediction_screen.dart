import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';

import 'package:flutter_app/core/theme/color_palette.dart';
import 'package:flutter_app/features/yield_prediction/providers/yield_provider.dart';
import 'package:flutter_app/features/yield_prediction/presentation/widgets/yield_chart_widget.dart';
import 'package:flutter_app/features/yield_prediction/domain/entities/yield_prediction.dart';
import 'package:flutter_app/features/yield_prediction/providers/language_provider.dart';
import 'package:flutter_app/features/financial_model/data/market_data_service.dart';
import 'package:flutter_app/features/financial_model/domain/financial_calculator.dart';
import 'package:flutter_app/features/financial_model/presentation/financial_outlook_widget.dart';
import 'package:flutter_app/features/yield_prediction/presentation/widgets/yield_header_card.dart';

class YieldPredictionScreen extends ConsumerStatefulWidget {
  const YieldPredictionScreen({super.key});

  @override
  ConsumerState<YieldPredictionScreen> createState() => _YieldPredictionScreenState();
}

class _YieldPredictionScreenState extends ConsumerState<YieldPredictionScreen> {
  static const List<String> _crops = ['Onion', 'Tomato', 'Potato', 'Rice', 'Wheat', 'Maize', 'Cotton', 'Sugarcane'];
  static const List<double> _areas = [0.5, 1.0, 1.25, 1.5, 1.75, 2.0, 2.25, 2.5, 2.75, 3.0, 3.25, 3.5, 3.75, 4.0, 4.25, 4.5, 4.75, 5.0, 6.0, 7.0, 8.0, 9.0, 10.0, 20.0, 50.0];
  static const List<String> _soils = ['Clay Loam', 'Sandy Loam', 'Silt Loam', 'Peat', 'Chalky', 'Black Soil', 'Red Soil'];
  static const Map<AppLanguage, String> _languageNames = {
    AppLanguage.en: "English",
    AppLanguage.hi: "हिन्दी (Hindi)",
    AppLanguage.ta: "தமிழ் (Tamil)",
    AppLanguage.kn: "ಕನ್ನಡ (Kannada)",
    AppLanguage.te: "తెలుగు (Telugu)",
    AppLanguage.ml: "മലയാളം (Malayalam)",
  };

  @override
  Widget build(BuildContext context) {
    final yieldState = ref.watch(yieldProvider);
    final yieldNotifier = ref.read(yieldProvider.notifier);
    final currentLanguage = ref.watch(languageProvider);
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
    
    // Listen for language changes to translate dynamic content
    ref.listen(languageProvider, (previous, next) {
      if (previous != next && yieldState.result != null) {
        final languageName = _languageNames[next] ?? "English";
        // Extract just the name from "Tamil (தமிழ்)" format if needed, 
        // but backend expects e.g. "Tamil" or "English"
        // The map values are "English", "हिन्दी (Hindi)", etc.
        // We need to pass a clean language name to the backend.
        final cleanName = next == AppLanguage.en ? "English" :
                          next == AppLanguage.hi ? "Hindi" :
                          next == AppLanguage.ta ? "Tamil" :
                          next == AppLanguage.kn ? "Kannada" :
                          next == AppLanguage.te ? "Telugu" : "Malayalam";
                          
        yieldNotifier.translateResult(cleanName);
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
        foregroundColor: ColorPalette.textPrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () {
              yieldNotifier.reset();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // 1. Full-Width Branding Header
          const YieldHeaderCard(),
          
          // 2. Main Split View (Sidebar + Result)
          Expanded(
            child: Row(
              children: [
                // LEFT SIDE: Input Panel (Sidebar)
                Container(
                  width: 700,
                  color: ColorPalette.offWhite,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Removed Branding Header from here
                      // ...
                      
                      Expanded(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.symmetric(horizontal: 24.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 8), // Padding fix
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
                        
                        const SizedBox(height: 24),
                        
                        // Row 1: Crop Name & Field Area
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildLabel(languageNotifier.translate('crop_name')),
                                  _buildDropdownField<String>(
                                    value: yieldState.cropName,
                                    items: _crops,
                                    onChanged: (val) => yieldNotifier.updateCropName(val ?? _crops.first),
                                    itemLabelMapper: (val) => languageNotifier.translate(val.toLowerCase()),
                                    icon: Icons.grass,
                                    label: languageNotifier.translate('crop_name'),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildLabel(languageNotifier.translate('field_area')),
                                  _buildDropdownField<double>(
                                    value: yieldState.fieldArea,
                                    items: _areas,
                                    onChanged: (val) => yieldNotifier.updateFieldArea(val ?? 1.0),
                                    itemLabelMapper: (val) => "$val ${languageNotifier.translate('acres')}",
                                    icon: Icons.location_on_outlined,
                                    label: languageNotifier.translate('field_area'),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),

                        // Row 2: Soil Type & Planted Date
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildLabel(languageNotifier.translate('soil_type')),
                                  _buildDropdownField<String>(
                                    value: yieldState.soilType,
                                    items: _soils,
                                    onChanged: (val) => yieldNotifier.updateSoilType(val ?? _soils.first),
                                    itemLabelMapper: (val) => languageNotifier.translate(val.toLowerCase().replaceAll(' ', '_')),
                                    icon: Icons.terrain,
                                    label: languageNotifier.translate('soil_type'),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 16),
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
                          ],
                        ),
                        const SizedBox(height: 20),

                        // Row 3: Expected Harvest Date (Full Width)
                        _buildLabel(languageNotifier.translate('expected_harvest_date')),
                        _buildDatePicker(
                          selectedDate: yieldState.expectedHarvestDate,
                          onChanged: yieldNotifier.updateExpectedHarvestDate,
                          icon: Icons.calendar_today_rounded,
                        ),
                        
                        if (yieldState.expectedHarvestDate != null && 
                            yieldState.expectedHarvestDate!.difference(DateTime.now()).inDays > 14)
                          Padding(
                            padding: const EdgeInsets.only(top: 12.0),
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFF9C4), // Light yellow
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: const Color(0xFFFBC02D).withOpacity(0.3)),
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
                          ),
                        const SizedBox(height: 32),

                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: ElevatedButton(
                            onPressed: yieldState.isLoading ? null : () => yieldNotifier.predictYield(),
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
                        ),
                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
                ),

                // System Health Card
                Padding(
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
                          style: GoogleFonts.outfit(color: Colors.white.withOpacity(0.6), fontSize: 10, height: 1.4),
                        ),
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.2),
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
                                    color: Colors.white.withOpacity(0.8),
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
                ),
              ],
            ),
          ),

          // RIGHT SIDE: Result Panel
          Expanded(
            child: Container(
              color: Colors.white,
              child: yieldState.isLoading
                  ? _buildLoadingState()
                  : yieldState.result != null
                      ? _buildResultContent(yieldState.result!)
                      : _buildResultPlaceholder(),
            ),
          ),
        ],
      ),
    ),
    ],
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
            color: ColorPalette.emeraldGreen.withOpacity(0.1),
          ).animate(onPlay: (controller) => controller.repeat())
           .shimmer(duration: 2000.ms, color: ColorPalette.mintGreen.withOpacity(0.2)),
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

  Widget _buildResultContent(YieldPrediction result) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildResultHeader(result),
          const SizedBox(height: 32),
          YieldChartWidget(dailyForecast: result.dailyForecast),
          const SizedBox(height: 32),
          _buildFinancialSection(result),
          const SizedBox(height: 32),
          _buildContextualInsights(result.contextualInsights),
          const SizedBox(height: 32),
          _buildFactorsCard(result),
          const SizedBox(height: 24),
          _buildRecommendationsCard(result),
        ],
      ).animate().fadeIn(duration: 800.ms),
    );
  }

  Widget _buildResultHeader(YieldPrediction result) {
    final languageNotifier = ref.read(languageProvider.notifier);
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                languageNotifier.translate('estimated_yield'),
                style: GoogleFonts.outfit(
                  color: ColorPalette.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    "${result.expectedYield}",
                    style: GoogleFonts.outfit(
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                      color: ColorPalette.textPrimary,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    "Qtl/Acre",
                    style: GoogleFonts.outfit(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: ColorPalette.textSecondary,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        // Confidence Score Widget (Circular)
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFF7F9FB),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            children: [
              Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 50,
                    height: 50,
                    child: CircularProgressIndicator(
                      value: result.confidence / 100,
                      strokeWidth: 6,
                      backgroundColor: Colors.grey.shade200,
                      valueColor: const AlwaysStoppedAnimation<Color>(ColorPalette.emeraldGreen),
                    ),
                  ),
                  Text(
                    "${result.confidence.toInt()}%",
                    style: GoogleFonts.outfit(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: ColorPalette.textPrimary,
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "CONFIDENCE SCORE",
                    style: GoogleFonts.outfit(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: ColorPalette.textSecondary,
                    ),
                  ),
                  Text(
                    "\"${languageNotifier.translate('high_reliability')}\"",
                    style: GoogleFonts.outfit(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      fontStyle: FontStyle.italic,
                      color: ColorPalette.textPrimary,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFactorsCard(YieldPrediction result) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          ref.read(languageProvider.notifier).translate('core_factors'),
          style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold, color: ColorPalette.textPrimary),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: result.primaryFactors.map<Widget>((factor) {
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: ColorPalette.emeraldGreen.withOpacity(0.08),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: ColorPalette.emeraldGreen.withOpacity(0.15)),
              ),
              child: Text(
                factor,
                style: GoogleFonts.outfit(color: ColorPalette.emeraldGreen, fontSize: 12, fontWeight: FontWeight.w500),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildRecommendationsCard(YieldPrediction result) {
    return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            ref.read(languageProvider.notifier).translate('ai_strategy'),
            style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold, color: ColorPalette.textPrimary),
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
              children: result.recommendations.map<Widget>((rec) => Padding(
                padding: const EdgeInsets.only(bottom: 12.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.check_circle_outline_rounded, color: ColorPalette.emeraldGreen, size: 18),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        rec, 
                        style: GoogleFonts.outfit(
                          color: ColorPalette.textPrimary,
                          fontSize: 14,
                          height: 1.4,
                        )
                      )
                    ),
                  ],
                ),
                )).toList(),
              ),
            ),
          ],
        );
  }

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

  InputDecoration _buildInputDecoration(String hintText, {IconData? trailingIcon}) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: GoogleFonts.outfit(color: ColorPalette.textSecondary.withOpacity(0.4), fontSize: 13),
      suffixIcon: trailingIcon != null ? Icon(trailingIcon, color: ColorPalette.textSecondary.withOpacity(0.4), size: 18) : null,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: ColorPalette.emeraldGreen, width: 1),
      ),
      filled: true,
      fillColor: const Color(0xFFF1F4F8),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    );
  }

  Widget _buildDropdownField<T>({
    required String label,
    required T value,
    required List<T> items,
    required Function(T?) onChanged,
    required IconData icon,
    String Function(T)? itemLabelMapper,
  }) {
    return DropdownButtonFormField<T>(
      value: value,
      isExpanded: true,
      dropdownColor: Colors.white,
      borderRadius: BorderRadius.circular(16),
      icon: const Icon(Icons.arrow_drop_down_rounded, color: ColorPalette.textSecondary),
      decoration: _buildInputDecoration("", trailingIcon: icon).copyWith(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      items: items.map((T item) {
        return DropdownMenuItem<T>(
          value: item,
          child: Text(
            itemLabelMapper != null ? itemLabelMapper(item) : item.toString(),
            style: GoogleFonts.outfit(fontSize: 14, color: ColorPalette.textPrimary),
          ),
        );
      }).toList(),
      onChanged: onChanged,
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
      child: IgnorePointer(
        child: TextField(
          decoration: _buildInputDecoration(
            selectedDate != null ? DateFormat('MM/dd/yyyy').format(selectedDate) : "MM/DD/YYYY",
            trailingIcon: icon,
          ),
          controller: TextEditingController(
            text: selectedDate != null ? DateFormat('MM/dd/yyyy').format(selectedDate) : "",
          ),
        ),
      ),
    );
  }

  Widget _buildContextualInsights(List<InsightCard> insights) {
    if (insights.isEmpty) return const SizedBox();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          ref.read(languageProvider.notifier).translate('contextual_insights'),
          style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold, color: ColorPalette.textPrimary),
        ),
        const SizedBox(height: 16),
        LayoutBuilder(
          builder: (context, constraints) {
            final cardWidth = (constraints.maxWidth - (3 * 16)) / 4;
            return Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: insights.map((insight) => _ContextualInsightCard(
                insight: insight,
                width: cardWidth,
              )).toList(),
            );
          }
        ),
      ],
    );
  }

  Widget _buildFinancialSection(YieldPrediction result) {
    // 1. Get Financial Data for the crop (Mock)
    final financialData = MarketDataService.getFinancialData(ref.read(yieldProvider).cropName);
    
    // 2. Calculate Metrics
    final metrics = FinancialCalculator.calculateMetrics(
      predictedYieldPerAcre: result.expectedYield,
      fieldAreaAcres: ref.read(yieldProvider).fieldArea,
      marketPricePerQuintal: financialData.marketPricePerQuintal,
      costPerAcre: financialData.cultivationCostPerAcre,
    );

    // 3. Render Widget
    return FinancialOutlookWidget(metrics: metrics, cropName: ref.read(yieldProvider).cropName);
  }
}

class _ContextualInsightCard extends StatelessWidget {
  final InsightCard insight;
  final double width;

  const _ContextualInsightCard({required this.insight, required this.width});

  @override
  Widget build(BuildContext context) {
    final languageNotifier = ProviderScope.containerOf(context).read(languageProvider.notifier);
    
    Color statusColor;
    IconData icon;
    
    switch (insight.status.toLowerCase()) {
      case 'optimal':
      case 'good':
        statusColor = const Color(0xFF4CAF50);
        break;
      case 'warning':
        statusColor = const Color(0xFFFF9800);
        break;
      case 'monitor':
        statusColor = const Color(0xFF2196F3);
        break;
      default:
        statusColor = ColorPalette.textSecondary;
    }

    switch (insight.iconType.toLowerCase()) {
      case 'thermometer':
        icon = Icons.thermostat_rounded;
        break;
      case 'droplet':
        icon = Icons.water_drop_rounded;
        break;
      case 'warning':
        icon = Icons.report_problem_rounded;
        break;
      case 'sun':
        icon = Icons.wb_sunny_rounded;
        break;
      default:
        icon = Icons.info_outline_rounded;
    }

    return Container(
      width: width,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(icon, color: ColorPalette.emeraldGreen, size: 20),
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(color: statusColor, shape: BoxShape.circle),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            languageNotifier.translate(insight.label.toLowerCase().replaceAll(' ', '_')),
            style: GoogleFonts.outfit(fontSize: 10, fontWeight: FontWeight.bold, color: ColorPalette.textSecondary),
          ),
          const SizedBox(height: 4),
          Text(
            insight.value,
            style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.bold, color: ColorPalette.textPrimary),
          ),
          const SizedBox(height: 8),
          Text(
            languageNotifier.translate(insight.status.toLowerCase()),
            style: GoogleFonts.outfit(fontSize: 10, fontWeight: FontWeight.w600, color: statusColor),
          ),
        ],
      ),
    );
  }
}
