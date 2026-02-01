import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../../core/theme/color_palette.dart';
import '../../domain/entities/yield_prediction.dart';
import '../../providers/language_provider.dart';

class YieldChartWidget extends ConsumerWidget {
  final List<DailyForecast> dailyForecast;

  const YieldChartWidget({
    super.key,
    required this.dailyForecast,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final languageNotifier = ref.read(languageProvider.notifier);
    return Container(
      height: 320,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F9FB),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                languageNotifier.translate('yield_trajectory'),
                style: GoogleFonts.outfit(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: ColorPalette.textPrimary,
                ),
              ),
              _buildLegend(languageNotifier),
            ],
          ),
          const SizedBox(height: 24),
          Expanded(
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: 100,
                barTouchData: BarTouchData(
                  touchTooltipData: BarTouchTooltipData(
                    tooltipBgColor: ColorPalette.textPrimary,
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      final day = dailyForecast[groupIndex];
                      return BarTooltipItem(
                        "${day.day}: ${day.temp}°C\n${day.condition}\nPotential: ${day.yieldPotential.toInt()}%",
                        GoogleFonts.outfit(color: Colors.white, fontSize: 11),
                      );
                    },
                  ),
                ),
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        if (value < 0 || value >= dailyForecast.length) return const SizedBox();
                        return Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Text(
                            dailyForecast[value.toInt()].day,
                            style: GoogleFonts.outfit(fontSize: 10, color: ColorPalette.textSecondary),
                          ),
                        );
                      },
                      reservedSize: 28,
                    ),
                  ),
                  leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (value) => FlLine(
                    color: Colors.grey.shade200,
                    strokeWidth: 1,
                    dashArray: [5, 5],
                  ),
                ),
                borderData: FlBorderData(show: false),
                barGroups: dailyForecast.asMap().entries.map((entry) {
                  final index = entry.key;
                  final day = entry.value;
                  final potential = day.yieldPotential;
                  
                  final color = potential > 70 
                      ? const Color(0xFF4CAF50) // Optimal
                      : const Color(0xFFFF7043); // Stress

                  return BarChartGroupData(
                    x: index,
                    barRods: [
                      BarChartRodData(
                        toY: potential,
                        color: color,
                        width: 16,
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                        backDrawRodData: BackgroundBarChartRodData(
                          show: true,
                          toY: 100,
                          color: Colors.grey.shade100,
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegend(LanguageNotifier languageNotifier) {
    return Row(
      children: [
        _buildLegendItem(languageNotifier.translate('optimal'), const Color(0xFF4CAF50)),
        const SizedBox(width: 16),
        _buildLegendItem(languageNotifier.translate('warning'), const Color(0xFFFF7043)),
      ],
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      children: [
        Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 6),
        Text(label, style: GoogleFonts.outfit(fontSize: 10, color: ColorPalette.textSecondary)),
      ],
    );
  }
}
