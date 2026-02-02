import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_app/core/theme/color_palette.dart';
import 'package:flutter_app/features/yield_prediction/domain/entities/yield_prediction.dart';
import 'package:flutter_app/features/yield_prediction/presentation/widgets/yield_chart_widget.dart';
import 'package:flutter_app/features/yield_prediction/providers/language_provider.dart';
import 'package:flutter_app/features/financial_model/data/market_data_service.dart';
import 'package:flutter_app/features/financial_model/domain/financial_calculator.dart';
import 'package:flutter_app/features/financial_model/presentation/financial_outlook_widget.dart';


class YieldResultView extends ConsumerWidget {
  final YieldPrediction result;
  final String cropName;
  final double fieldArea;

  const YieldResultView({
    super.key,
    required this.result,
    required this.cropName,
    required this.fieldArea,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final languageNotifier = ref.read(languageProvider.notifier);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildResultHeader(result, languageNotifier),
          const SizedBox(height: 32),
          YieldChartWidget(dailyForecast: result.dailyForecast),
          const SizedBox(height: 32),
          _buildFinancialSection(ref),
          const SizedBox(height: 32),
          _buildContextualInsights(result.contextualInsights, languageNotifier),
          const SizedBox(height: 32),
          _buildFactorsCard(result, languageNotifier),
          const SizedBox(height: 24),
          _buildRecommendationsCard(result, languageNotifier),
        ],
      ).animate().fadeIn(duration: 800.ms),
    );
  }

  Widget _buildResultHeader(YieldPrediction result, dynamic languageNotifier) {
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

  Widget _buildFactorsCard(YieldPrediction result, dynamic languageNotifier) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          languageNotifier.translate('core_factors'),
          style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold, color: ColorPalette.textPrimary),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: result.primaryFactors.map((factor) {
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

  Widget _buildRecommendationsCard(YieldPrediction result, dynamic languageNotifier) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          languageNotifier.translate('ai_strategy'),
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
        ),
      ],
    );
  }

  Widget _buildContextualInsights(List<InsightCard> insights, dynamic languageNotifier) {
    if (insights.isEmpty) return const SizedBox();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          languageNotifier.translate('contextual_insights'),
          style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold, color: ColorPalette.textPrimary),
        ),
        const SizedBox(height: 16),
        LayoutBuilder(
          builder: (context, constraints) {
            // Adjust card width for small screens or sideway panel
            final cardWidth = constraints.maxWidth > 500 
                ? (constraints.maxWidth - (3 * 16)) / 4
                : (constraints.maxWidth - 16) / 2;
            
            if (constraints.maxWidth > 500) {
              return Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: insights.map((insight) => _ContextualInsightCard(
                  insight: insight,
                  width: cardWidth,
                )).toList(),
              );
            } else {
              return Wrap(
                spacing: 16,
                runSpacing: 16,
                children: insights.map((insight) => _ContextualInsightCard(
                  insight: insight,
                  width: cardWidth,
                )).toList(),
              );
            }
          }
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
            insight.label, // Categories usually stay in English for mapping
            style: GoogleFonts.outfit(fontSize: 10, fontWeight: FontWeight.bold, color: ColorPalette.textSecondary),
          ),
          const SizedBox(height: 4),
          Text(
            insight.value,
            style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.bold, color: ColorPalette.textPrimary),
          ),
          const SizedBox(height: 8),
          Text(
            insight.status,
            style: GoogleFonts.outfit(fontSize: 10, fontWeight: FontWeight.w600, color: statusColor),
          ),
        ],
      ),
    );
  }
}
