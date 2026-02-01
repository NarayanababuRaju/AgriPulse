import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_app/core/theme/color_palette.dart';
import 'package:flutter_app/core/api/agri_pulse_service.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';

class MiniForecastWidget extends ConsumerStatefulWidget {
  const MiniForecastWidget({super.key});

  @override
  ConsumerState<MiniForecastWidget> createState() => _MiniForecastWidgetState();
}

class _MiniForecastWidgetState extends ConsumerState<MiniForecastWidget> {
  bool isLoading = true;
  List<dynamic> forecast = [];

  @override
  void initState() {
    super.initState();
    _loadForecast();
  }

  Future<void> _loadForecast() async {
    try {
      // Hardcoded location for MVP (Namakkal)
      final data = await ref.read(agriPulseServiceProvider).getForecast(11.2189, 78.1674);
      if (mounted) {
        setState(() {
          forecast = data['daily_summary'] ?? [];
          isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => isLoading = false);
      }
      debugPrint("Forecast Load Error: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) return _buildShimmer();
    if (forecast.isEmpty) return const SizedBox.shrink();

    // Take exactly 7 days
    final displayForecast = forecast.length > 7 ? forecast.sublist(0, 7) : forecast;

    return Container(
      height: 70, // Increased from 52
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FA), 
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: displayForecast.map((day) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  _formatDay(day['time']), // Properly parsed day
                  style: GoogleFonts.outfit(
                    fontSize: 12, // Increased from 10
                    fontWeight: FontWeight.bold,
                    color: ColorPalette.textSecondary,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      _getIcon(day['condition']),
                      size: 18, // Increased from 14
                      color: _getIconColor(day['condition']),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      "${day['temp'].round()}°",
                      style: GoogleFonts.outfit(
                        fontSize: 14, // Increased from 11
                        fontWeight: FontWeight.w600,
                        color: ColorPalette.textPrimary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  String _formatDay(String timeOrDate) {
    // If it's "Today", "Tomorrow", etc. return shortened version
    if (timeOrDate.toLowerCase().contains("today")) return "TOD";
    if (timeOrDate.toLowerCase().contains("tomorrow")) return "TOM";
    
    // Try parse date
    try {
      final date = DateTime.parse(timeOrDate);
      return DateFormat('E').format(date).toUpperCase(); // MON, TUE
    } catch (_) {
      // Fallback
      return timeOrDate.length > 3 ? timeOrDate.substring(0, 3).toUpperCase() : timeOrDate.toUpperCase();
    }
  }

  IconData _getIcon(String condition) {
    condition = condition.toLowerCase();
    if (condition.contains('rain')) return Icons.water_drop_rounded;
    if (condition.contains('cloud')) return Icons.cloud_rounded;
    return Icons.wb_sunny_rounded;
  }

  Color _getIconColor(String condition) {
    condition = condition.toLowerCase();
    if (condition.contains('rain')) return Colors.blue;
    if (condition.contains('cloud')) return Colors.grey;
    return Colors.orange;
  }

  Widget _buildShimmer() {
    return Container(
      height: 60,
      width: 300,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
    ).animate(onPlay: (c) => c.repeat()).shimmer(color: Colors.grey.withOpacity(0.2));
  }
}
