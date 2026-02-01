import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_app/core/theme/color_palette.dart';
import '../../../../core/components/loading_shimmer.dart';

/// WeatherCard - Displays current weather information
/// 
/// A visually appealing card using a gradient background to represent 
/// the "Earth & Growth" theme. Supports Shimmer Loading.

class WeatherCard extends StatelessWidget {
  final bool isLoading;
  final String condition;
  final int temperature;
  final String location;
  final DateTime? date;

  const WeatherCard({
    super.key, 
    this.isLoading = false,
    this.condition = "Sunny", 
    this.temperature = 28,
    this.location = "Namakkal, Tamil Nadu",
    this.date,
  });

  LinearGradient _getWeatherGradient() {
    final cond = condition.toLowerCase();
    
    if (cond.contains('sunny') || cond.contains('clear')) {
      // Cold & Sunny/Clear? (e.g. Winter morning)
      if (temperature < 25) {
        return const LinearGradient(
          colors: [Color(0xFF4FC3F7), Color(0xFF0288D1)], // Light Blue to Blue (Cool)
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      }
      // Warm & Sunny
      return const LinearGradient(
        colors: [Color(0xFFFFB300), Color(0xFFFF6F00)], // Amber to Orange (Warm)
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );
    } else if (cond.contains('cloud') || cond.contains('rain')) {
      // Cloudy/Rain: Bluish-Grey
      return const LinearGradient(
        colors: [Color(0xFF90A4AE), Color(0xFF546E7A)], // BlueGrey 300-600
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );
    } else {
      // Default/Normal: Green (Growth)
       return const LinearGradient(
          colors: [ColorPalette.emeraldGreen, Color(0xFF43A047)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) return _buildSkeleton();
    
    final displayDate = date ?? DateTime.now();
    final dateStr = "Today, ${DateFormat('d MMM').format(displayDate)}";

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: _getWeatherGradient(),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Location Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      location,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      dateStr,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                // ... icon ...
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: const BoxDecoration(
                    color: Colors.white24,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    condition == "Sunny" ? Icons.wb_sunny_rounded : Icons.cloud,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 24),
            
            // Temperature & Condition
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  "$temperature°",
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 48,
                    fontWeight: FontWeight.bold,
                    height: 1,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(bottom: 8, left: 8),
                  child: Text(
                    condition,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 8),
            
            // Footer Info (Humidity / Wind) - Mock Data
            Row(
              children: const [
                Icon(Icons.water_drop_outlined, color: Colors.white70, size: 16),
                SizedBox(width: 4),
                Text(
                  "45%",
                  style: TextStyle(color: Colors.white70, fontSize: 12),
                ),
                SizedBox(width: 16),
                Icon(Icons.air, color: Colors.white70, size: 16),
                SizedBox(width: 4),
                Text(
                  "12 km/h",
                  style: TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _buildSkeleton() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Skeleton
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    LoadingShimmer(width: 140, height: 20),
                    SizedBox(height: 8),
                    LoadingShimmer(width: 100, height: 14),
                  ],
                ),
                const LoadingShimmer(width: 40, height: 40, radius: 20),
              ],
            ),
            const SizedBox(height: 24),
            // Temp Skeleton
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: const [
                LoadingShimmer(width: 80, height: 48),
                SizedBox(width: 16),
                LoadingShimmer(width: 60, height: 24),
              ],
            ),
            const SizedBox(height: 16),
            // Footer Skeleton
            const LoadingShimmer(width: 200, height: 16),
          ],
        ),
      ),
    );
  }
}
