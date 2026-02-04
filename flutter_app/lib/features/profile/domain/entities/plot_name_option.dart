import 'package:flutter/material.dart';

/// PlotNameOption - Predefined plant/crop-based plot name suggestions
class PlotNameOption {
  final String id;
  final String nameKey; // Translation key
  final IconData icon;

  const PlotNameOption({
    required this.id,
    required this.nameKey,
    required this.icon,
  });

  static const List<PlotNameOption> defaults = [
    PlotNameOption(
      id: 'rice',
      nameKey: 'rice_field',
      icon: Icons.grass_rounded,
    ),
    PlotNameOption(
      id: 'wheat',
      nameKey: 'wheat_field',
      icon: Icons.agriculture_rounded,
    ),
    PlotNameOption(
      id: 'corn',
      nameKey: 'corn_field',
      icon: Icons.eco_rounded,
    ),
    PlotNameOption(
      id: 'onion',
      nameKey: 'onion_field',
      icon: Icons.circle_outlined,
    ),
    PlotNameOption(
      id: 'tomato',
      nameKey: 'tomato_field',
      icon: Icons.emoji_food_beverage_rounded,
    ),
    PlotNameOption(
      id: 'cotton',
      nameKey: 'cotton_field',
      icon: Icons.cloud_outlined,
    ),
    PlotNameOption(
      id: 'sugarcane',
      nameKey: 'sugarcane_field',
      icon: Icons.spa_rounded,
    ),
    PlotNameOption(
      id: 'vegetable',
      nameKey: 'vegetable_patch',
      icon: Icons.local_florist_rounded,
    ),
    PlotNameOption(
      id: 'custom',
      nameKey: 'custom_input',
      icon: Icons.edit_rounded,
    ),
  ];
}
