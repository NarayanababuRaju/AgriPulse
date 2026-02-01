import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';

import 'package:flutter_app/core/theme/color_palette.dart';
import 'package:flutter_app/features/yield_prediction/providers/language_provider.dart';
import 'package:flutter_app/features/financial_model/domain/financial_calculator.dart';

class FinancialOutlookWidget extends ConsumerWidget {
  final FinancialMetrics metrics;
  final String cropName;

  const FinancialOutlookWidget({
    super.key,
    required this.metrics,
    required this.cropName,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final languageNotifier = ref.read(languageProvider.notifier);
    final currencyFormatter = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 15,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F5E9),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.currency_rupee_rounded, color: ColorPalette.emeraldGreen, size: 20),
              ),
              const SizedBox(width: 12),
              Text(
                languageNotifier.translate('financial_outlook'),
                style: GoogleFonts.outfit(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: ColorPalette.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          
          // ROI Indicator
          Row(
            children: [
              Expanded(
                child: _buildMetricCard(
                  label: languageNotifier.translate('projected_revenue'),
                  value: currencyFormatter.format(metrics.grossRevenue),
                  valueColor: ColorPalette.emeraldGreen,
                  icon: Icons.trending_up_rounded,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildMetricCard(
                  label: languageNotifier.translate('estimated_cost'),
                  value: currencyFormatter.format(metrics.totalCost),
                  valueColor: ColorPalette.textSecondary,
                  icon: Icons.receipt_long_rounded,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF8F9FA),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      languageNotifier.translate('net_profit'),
                      style: GoogleFonts.outfit(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: ColorPalette.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      currencyFormatter.format(metrics.netProfit),
                      style: GoogleFonts.outfit(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: metrics.netProfit >= 0 ? const Color(0xFF2E7D32) : Colors.red,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: metrics.roiPercentage >= 0 ? const Color(0xFFE8F5E9) : const Color(0xFFFFEBEE),
                    borderRadius: BorderRadius.circular(100),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        metrics.roiPercentage >= 0 ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded,
                        size: 16,
                        color: metrics.roiPercentage >= 0 ? const Color(0xFF2E7D32) : Colors.red,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        "${metrics.roiPercentage.toStringAsFixed(1)}% ROI",
                        style: GoogleFonts.outfit(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: metrics.roiPercentage >= 0 ? const Color(0xFF2E7D32) : Colors.red,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
           const SizedBox(height: 12),
           Text(
             languageNotifier.translate('financial_disclaimer').replaceAll('{cropName}', cropName),
             style: GoogleFonts.outfit(
               fontSize: 11,
               color: ColorPalette.textSecondary.withOpacity(0.6),
               fontStyle: FontStyle.italic,
             ),
           ),
        ],
      ),
    ).animate().fadeIn().slideY(begin: 0.1, end: 0, duration: 600.ms);
  }

  Widget _buildMetricCard({
    required String label,
    required String value,
    required Color valueColor,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: ColorPalette.textSecondary.withOpacity(0.5)),
              const SizedBox(width: 6),
              Flexible( // Added Flexible to prevent overflow
                child: Text(
                  label,
                  style: GoogleFonts.outfit(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: ColorPalette.textSecondary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: GoogleFonts.outfit(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: valueColor,
            ),
          ),
        ],
      ),
    );
  }
}
