import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter_app/features/profile/presentation/screens/onboarding_screen.dart';

import 'package:flutter_app/core/services/local_vault.dart';

void main() {
  late Directory tempDir;

  setUp(() async {
    final binding = TestWidgetsFlutterBinding.ensureInitialized();
    binding.platformDispatcher.implicitView!.physicalSize = const Size(1920, 1080);
    binding.platformDispatcher.implicitView!.devicePixelRatio = 1.0;

    tempDir = Directory.systemTemp.createTempSync();
    Hive.init(tempDir.path);
    await LocalVault().init();
  });

  tearDown(() {
    final binding = TestWidgetsFlutterBinding.ensureInitialized();
    binding.platformDispatcher.implicitView!.resetPhysicalSize();
    binding.platformDispatcher.implicitView!.resetDevicePixelRatio();
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  testWidgets('FarmSetupWizard renders look and layout correctly', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: FarmSetupWizard(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // 1. Welcome Step Layout
    expect(find.byIcon(Icons.agriculture_rounded), findsOneWidget);
    expect(find.text('Welcome to AgriPulse'), findsOneWidget);
    expect(find.text('Plot Name'), findsOneWidget);
    expect(find.text('Approximate Acreage'), findsOneWidget);
    
    // 2. Button and Indicator
    expect(find.text('Continue'), findsOneWidget);
    expect(find.byType(ElevatedButton), findsOneWidget);

    // 3. Navigation to Step 2
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();

    expect(find.text('Soil & Environment'), findsOneWidget);
    expect(find.text('Select Soil Texture'), findsOneWidget);
    
    // 4. Checking for SelectionCards (UI component for look)
    expect(find.text('Clay Loam'), findsOneWidget);
    expect(find.text('EXCELLENT WATER RETENTION, HIGH NUTRIENTS.'), findsOneWidget);

    // 5. Navigation to Step 3
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();

    expect(find.text('Irrigation Method'), findsOneWidget);
    expect(find.text('Drip'), findsOneWidget);
    expect(find.text('Finish Setup'), findsOneWidget);
  });
}
