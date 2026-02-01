import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:agri_pulse/features/yield_prediction/presentation/screens/yield_prediction_screen.dart';

void main() {
  testWidgets('YieldPredictionScreen renders correctly', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: YieldPredictionScreen(),
        ),
      ),
    );

    // Verify critical UI elements are present
    expect(find.text('AI Yield Predictor'), findsOneWidget); // App Bar Title
    expect(find.text('Crop Details'), findsOneWidget); // Section Header
    expect(find.text('Field Area (Acres)'), findsOneWidget); // Input Label
    
    // Check if the "Predict Yield" button exists
    expect(find.text('Analyze & Predict Yield'), findsOneWidget);
  });
}
