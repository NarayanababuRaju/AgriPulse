import 'package:flutter/material.dart';

class SoilType {
  final String id;
  final String nameKey;
  final String localNameKey;
  final String descriptionKey;
  final IconData icon;

  const SoilType({
    required this.id,
    required this.nameKey,
    required this.localNameKey,
    required this.descriptionKey,
    required this.icon,
  });

  static const List<SoilType> defaults = [
    SoilType(
      id: 'clay_loam',
      nameKey: 'clay_loam',
      localNameKey: 'ta', // Special case: we can use language code or specific keys
      descriptionKey: 'clay_loam_desc',
      icon: Icons.layers_rounded,
    ),
    SoilType(
      id: 'sandy',
      nameKey: 'sandy_soil',
      localNameKey: 'ta',
      descriptionKey: 'sandy_soil_desc',
      icon: Icons.waves_rounded,
    ),
    SoilType(
      id: 'red_loamy',
      nameKey: 'red_loamy',
      localNameKey: 'ta',
      descriptionKey: 'red_loamy_desc',
      icon: Icons.landscape_rounded,
    ),
    SoilType(
      id: 'black_cotton',
      nameKey: 'black_cotton',
      localNameKey: 'ta',
      descriptionKey: 'black_cotton_desc',
      icon: Icons.brightness_3_rounded,
    ),
  ];
}
