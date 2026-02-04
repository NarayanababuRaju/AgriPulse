import 'package:flutter/material.dart';

/// AcreageRangeOption - Predefined acreage range suggestions
class AcreageRangeOption {
  final String id;
  final String labelKey; // Translation key
  final double minValue;
  final double maxValue;
  final IconData icon;

  const AcreageRangeOption({
    required this.id,
    required this.labelKey,
    required this.minValue,
    required this.maxValue,
    required this.icon,
  });

  /// Returns the midpoint value for saving to database
  double get midpoint => (minValue + maxValue) / 2;

  static const List<AcreageRangeOption> defaults = [
    AcreageRangeOption(
      id: 'small',
      labelKey: 'acreage_small',
      minValue: 0.1,
      maxValue: 1.0,
      icon: Icons.filter_1_rounded,
    ),
    AcreageRangeOption(
      id: 'medium',
      labelKey: 'acreage_medium',
      minValue: 1.0,
      maxValue: 2.0,
      icon: Icons.filter_2_rounded,
    ),
    AcreageRangeOption(
      id: 'large',
      labelKey: 'acreage_large',
      minValue: 2.0,
      maxValue: 5.0,
      icon: Icons.filter_3_rounded,
    ),
    AcreageRangeOption(
      id: 'very_large',
      labelKey: 'acreage_very_large',
      minValue: 5.0,
      maxValue: 10.0,
      icon: Icons.filter_4_rounded,
    ),
    AcreageRangeOption(
      id: 'estate',
      labelKey: 'acreage_estate',
      minValue: 10.0,
      maxValue: 50.0,
      icon: Icons.filter_5_rounded,
    ),
    AcreageRangeOption(
      id: 'custom',
      labelKey: 'custom_input',
      minValue: 0.0,
      maxValue: 0.0,
      icon: Icons.edit_rounded,
    ),
  ];
}
