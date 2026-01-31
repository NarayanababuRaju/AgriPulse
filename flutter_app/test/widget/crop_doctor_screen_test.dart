import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_app/features/crop_diagnosis/presentation/crop_doctor_screen.dart';

/// Widget Tests for Crop Doctor Screen
/// 
/// Tests the crop diagnosis UI and image picker interactions.
void main() {
  group('CropDoctorScreen Widget Tests', () {
    testWidgets('should display title and instructions', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: const MaterialApp(
            home: CropDoctorScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.text('Crop Doctor'), findsOneWidget);
      expect(find.text('Take a clear photo of the affected plant area'), findsOneWidget);
    });

    testWidgets('should show image picker in empty state', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: const MaterialApp(
            home: CropDoctorScreen(),
          ),
        ),
      );
      
      await tester.pumpAndSettle();

      expect(find.text('Upload Image'), findsOneWidget);
      expect(find.text('Camera'), findsOneWidget);
      expect(find.text('Gallery'), findsOneWidget);
      expect(find.byIcon(Icons.add_a_photo_outlined), findsOneWidget);
    });

    testWidgets('should not show Analyze button in empty state', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: const MaterialApp(
            home: CropDoctorScreen(),
          ),
        ),
      );
      
      await tester.pumpAndSettle();

      // Analyze button should not exist when no image is selected
      expect(find.text('Analyze Crop'), findsNothing);
    });

    testWidgets('Camera button should be tappable', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: const MaterialApp(
            home: CropDoctorScreen(),
          ),
        ),
      );
      
      await tester.pumpAndSettle();

      final cameraButton = find.text('Camera');
      expect(cameraButton, findsOneWidget);
      
      // Verify button is tappable (actual picker won't open in tests)
      await tester.tap(cameraButton);
      await tester.pumpAndSettle();
      
      // No error should occur
    });

    testWidgets('Gallery button should be tappable', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: const MaterialApp(
            home: CropDoctorScreen(),
          ),
        ),
      );
      
      await tester.pumpAndSettle();

      final galleryButton = find.text('Gallery');
      expect(galleryButton, findsOneWidget);
      
      await tester.tap(galleryButton);
      await tester.pumpAndSettle();
      
      // No error should occur
    });

    testWidgets('back button should be present', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: const MaterialApp(
            home: CropDoctorScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.arrow_back_ios_new_rounded), findsOneWidget);
    });

    testWidgets('should display support text', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: const MaterialApp(
            home: CropDoctorScreen(),
          ),
        ),
      );
      
      await tester.pumpAndSettle();

      expect(find.text('Supports: JPG, PNG'), findsOneWidget);
    });
  });
}
