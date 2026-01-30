import 'package:flutter/material.dart';
import 'package:flutter_app/core/theme/color_palette.dart';

/// RecentActivityList - Displays a list of recent actions/diagnoses
/// 
/// Currently a placeholder with a "No recent activity" state.
/// Future integration: Connect to Firestore to fetch past Diagnosis reports.
class RecentActivityList extends StatelessWidget {
  const RecentActivityList({super.key});

  @override
  Widget build(BuildContext context) {
    // Mocking an empty list for "Day 1" user experience
    // final hasActivity = false; 

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Recent Activity",
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: ColorPalette.textPrimary,
          ),
        ),
        const SizedBox(height: 16),
        _buildEmptyState(),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          Icon(Icons.history_edu, size: 48, color: Colors.grey.shade300),
          const SizedBox(height: 12),
          const Text(
            "No recent scans",
            style: TextStyle(
              color: ColorPalette.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
          const Text(
            "Your diagnosis reports will appear here",
            style: TextStyle(color: Colors.grey, fontSize: 12),
          ),
        ],
      ),
    );
  }
}
