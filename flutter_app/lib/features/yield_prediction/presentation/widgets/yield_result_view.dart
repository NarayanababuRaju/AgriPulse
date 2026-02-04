import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_app/core/theme/color_palette.dart';
import 'package:flutter_app/features/yield_prediction/domain/entities/yield_prediction.dart';
import 'package:flutter_app/features/yield_prediction/presentation/widgets/yield_chart_widget.dart';
import 'package:flutter_app/core/localization/language_provider.dart';
import 'package:flutter_app/features/financial_model/data/market_data_service.dart';
import 'package:flutter_app/features/financial_model/domain/financial_calculator.dart';
import 'package:flutter_app/features/financial_model/presentation/financial_outlook_widget.dart';


class YieldResultView extends ConsumerWidget {
  final YieldPrediction result;
  final String cropName;
  final double fieldArea;
  final bool isCompact;

  const YieldResultView({
    super.key,
    required this.result,
    required this.cropName,
    required this.fieldArea,
    this.isCompact = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch language state to trigger rebuilds on language change
    ref.watch(languageProvider);
    final languageNotifier = ref.read(languageProvider.notifier);

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. LEFT COLUMN: Metrics & Financial Story
          Expanded(
            flex: 4,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildYieldSection(result, languageNotifier),
                  const SizedBox(height: 32),
                  _buildContextualInsightsContent(result.contextualInsights, languageNotifier),
                  const SizedBox(height: 32),
                  _buildFinancialSection(ref),
                ],
              ),
            ),
          ),
          
          const SizedBox(width: 32),

          // 2. RIGHT COLUMN: Evidence & Strategy
          Expanded(
            flex: 8,
            child: Column(
              children: [
                // Top: Fixed Trajectory Chart
                YieldChartWidget(dailyForecast: result.dailyForecast),
                const SizedBox(height: 24),
                // Bottom: Scrollable Strategy (Factors + Recommendations)
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.grey.shade100),
                    ),
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildFactorsCard(result, languageNotifier),
                          const SizedBox(height: 24),
                          _buildRecommendationsCard(result, languageNotifier),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 800.ms);
  }

  Widget _buildYieldSection(YieldPrediction result, dynamic languageNotifier) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 3,
            child: _buildYield(result, languageNotifier),
          ),
          Container(
            height: 60,
            width: 1,
            color: Colors.grey.shade100,
            margin: const EdgeInsets.symmetric(horizontal: 16),
          ),
          Expanded(
            flex: 4,
            child: _buildConfidenceIndicator(result, languageNotifier),
          ),
        ],
      ),
    );
  }

  Widget _buildConfidenceIndicator(YieldPrediction result, dynamic languageNotifier) {
    final confidence = result.confidence;
    Color statusColor;
    String reliabilityKey;

    if (confidence < 60) {
      statusColor = ColorPalette.rustRed;
      reliabilityKey = 'low_reliability';
    } else if (confidence < 80) {
      statusColor = ColorPalette.amber;
      reliabilityKey = 'medium_reliability';
    } else {
      statusColor = ColorPalette.emeraldGreen;
      reliabilityKey = 'high_reliability';
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            SizedBox(
              width: 32,
              height: 32,
              child: CircularProgressIndicator(
                value: confidence / 100,
                strokeWidth: 4,
                backgroundColor: statusColor.withValues(alpha: 0.1),
                valueColor: AlwaysStoppedAnimation<Color>(statusColor),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              "${confidence.toInt()}%",
              style: GoogleFonts.outfit(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: statusColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              languageNotifier.translate('confidence_level').toUpperCase(),
              style: GoogleFonts.outfit(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: ColorPalette.textSecondary,
                letterSpacing: 0.5,
              ),
            ),
            Text(
              languageNotifier.translate(reliabilityKey),
              style: GoogleFonts.outfit(
                fontSize: 14,
                color: statusColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildYield(YieldPrediction result, dynamic languageNotifier) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          languageNotifier.translate('estimated_yield').toUpperCase(),
          style: GoogleFonts.outfit(
            color: ColorPalette.textSecondary,
            fontSize: 10,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.0,
          ),
        ),
        const SizedBox(height: 4),
        Wrap(
          crossAxisAlignment: WrapCrossAlignment.end,
          spacing: 4,
          children: [
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                "${result.expectedYield}",
                style: GoogleFonts.outfit(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: ColorPalette.textPrimary,
                ),
              ),
            ),
            Text(
              languageNotifier.translate('qtl_acre'),
              style: GoogleFonts.outfit(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: ColorPalette.textSecondary,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildFactorsCard(YieldPrediction result, dynamic languageNotifier) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          languageNotifier.translate('core_factors'),
          style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold, color: ColorPalette.textPrimary),
        ),
        const SizedBox(height: 16),
        _buildFactorsCardContent(result, languageNotifier),
      ],
    );
  }

  Widget _buildFactorsCardContent(YieldPrediction result, dynamic languageNotifier) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: result.primaryFactors.map((factor) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: ColorPalette.emeraldGreen.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: ColorPalette.emeraldGreen.withValues(alpha: 0.15)),
          ),
          child: Text(
            factor,
            style: GoogleFonts.outfit(color: ColorPalette.emeraldGreen, fontSize: 12, fontWeight: FontWeight.w500),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildRecommendationsCard(YieldPrediction result, dynamic languageNotifier) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          languageNotifier.translate('ai_strategy'),
          style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold, color: ColorPalette.textPrimary),
        ),
        const SizedBox(height: 16),
        _buildRecommendationsCardContent(result, languageNotifier),
      ],
    );
  }

  Widget _buildRecommendationsCardContent(YieldPrediction result, dynamic languageNotifier) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ColorPalette.offWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: result.recommendations.map((rec) => Padding(
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
    );
  }


  Widget _buildContextualInsightsContent(List<InsightCard> insights, dynamic languageNotifier) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          languageNotifier.translate('contextual_insights').toUpperCase(),
          style: GoogleFonts.outfit(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            color: ColorPalette.textSecondary,
            letterSpacing: 1.0,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: insights.map((insight) => _ContextualInsightCard(
            insight: insight,
            width: 145, 
          )).toList(),
        ),
      ],
    );
  }


  Widget _buildFinancialSection(WidgetRef ref) {
    final financialData = MarketDataService.getFinancialData(cropName);
    
    final metrics = FinancialCalculator.calculateMetrics(
      predictedYieldPerAcre: result.expectedYield,
      fieldAreaAcres: fieldArea,
      marketPricePerQuintal: financialData.marketPricePerQuintal,
      costPerAcre: financialData.cultivationCostPerAcre,
    );

    return FinancialOutlookWidget(metrics: metrics, cropName: cropName);
  }
}

class _ContextualInsightCard extends StatelessWidget {
  final InsightCard insight;
  final double width;

  const _ContextualInsightCard({required this.insight, required this.width});

  @override
  Widget build(BuildContext context) {
    // We cannot use ref.read here directly because it's a StatelessWidget
    // But we can get the language notifier via ProviderScope.containerOf in most cases 
    // or just pass it down. 
    // Let's use a simpler approach for now since it's a sub-widget.
    
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
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(icon, color: ColorPalette.emeraldGreen, size: 14),
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(color: statusColor, shape: BoxShape.circle),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            insight.label.toUpperCase(),
            style: GoogleFonts.outfit(fontSize: 8, fontWeight: FontWeight.bold, color: ColorPalette.textSecondary, letterSpacing: 0.5),
          ),
          const SizedBox(height: 2),
          Text(
            insight.value,
            style: GoogleFonts.outfit(fontSize: 11, fontWeight: FontWeight.bold, color: ColorPalette.textPrimary),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            insight.status,
            style: GoogleFonts.outfit(fontSize: 8, fontWeight: FontWeight.w600, color: statusColor),
          ),
        ],
      ),
    );
  }
}
