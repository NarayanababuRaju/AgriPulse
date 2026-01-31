import 'package:flutter/material.dart';

abstract class ColorPalette {
  /// Primary Color: Emerald Green - Represents growth, nature, and trust.
  static const Color emeraldGreen = Color(0xFF2E7D32);
  
  /// Primary Variant: Darker Green for depth.
  static const Color darkGreen = Color(0xFF1B5E20);

  /// Secondary Color: Golden Sunlight - Represents energy, yield, and harvest.
  static const Color goldenSunlight = Color(0xFFFFC107);
  
  /// Secondary Variant: Amber for warmer tones.
  static const Color amber = Color(0xFFFFA000);

  /// Surface Color: Off-White - Clean background, easy on the eyes.
  static const Color offWhite = Color(0xFFF5F5F5);
  
  /// Surface Variant: White for cards.
  static const Color white = Colors.white;

  /// Error Color: Rust Red - Represents disease or issues.
  static const Color rustRed = Color(0xFFC62828);
  
  /// Text Colors
  static const Color textPrimary = Color(0xFF212121); // Almost Black
  static const Color textSecondary = Color(0xFF757575); // Grey
  
  /// Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [emeraldGreen, Color(0xFF43A047)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
