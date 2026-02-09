import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter_app/features/dashboard/presentation/screens/activity_history_screen.dart';
import 'package:flutter_app/features/dashboard/presentation/providers/activity_provider.dart';
import 'package:flutter_app/features/crop_diagnosis/models/diagnosis_record.dart';
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

  testWidgets('ActivityHistoryScreen renders master-detail look correctly on desktop', (tester) async {
    // 1. Setup mock activity data
    final mockRecord = ActivityRecord(
      id: 'test_1',
      title: 'Healthy Plant',
      subtitle: 'Diagnosis Result',
      timestamp: DateTime.now(),
      type: ActivityType.diagnosis,
      confidence: 0.95,
      originalRecord: DiagnosisRecord(
        id: 'test_1',
        imagePath: '',
        diseaseName: 'Healthy Plant',
        confidence: 0.95,
        treatmentSummary: 'Continue regular care',
        timestamp: DateTime.now(),
      ),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          dashboardActivityProvider.overrideWith((ref) => Future.value([mockRecord])),
        ],
        child: const MaterialApp(
          home: ActivityHistoryScreen(),
        ),
      ),
    );

    // Wait for the FutureProvider to resolve
    await tester.pump(); // Start loading
    await tester.pump(); // Finish loading

    // 2. Verify Desktop Layout (Master-Detail)
    expect(find.text('Activity Log'), findsOneWidget);
    expect(find.byType(TextField), findsOneWidget); // Search field
    expect(find.text('Healthy Plant'), findsWidgets); // Master tile and detail title
    
    // Check for "Detailed Report" header in the detail pane
    expect(find.text('Detailed Report'), findsOneWidget);
    expect(find.byIcon(Icons.description_outlined), findsOneWidget);

    // 3. Verify fallback icon look
    expect(find.byIcon(Icons.local_hospital_rounded), findsWidgets);
  });

  testWidgets('ActivityHistoryScreen renders simple list on mobile', (tester) async {
    final binding = TestWidgetsFlutterBinding.ensureInitialized();
    binding.platformDispatcher.implicitView!.physicalSize = const Size(400, 800);

    final mockRecord = ActivityRecord(
      id: 'test_1',
      title: 'Healthy Plant',
      subtitle: 'Diagnosis Result',
      timestamp: DateTime.now(),
      type: ActivityType.diagnosis,
      confidence: 0.95,
      originalRecord: DiagnosisRecord(
        id: 'test_1',
        imagePath: '',
        diseaseName: 'Healthy Plant',
        confidence: 0.95,
        treatmentSummary: 'Continue regular care',
        timestamp: DateTime.now(),
      ),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          dashboardActivityProvider.overrideWith((ref) => Future.value([mockRecord])),
        ],
        child: const MaterialApp(
          home: ActivityHistoryScreen(),
        ),
      ),
    );

    await tester.pump();
    await tester.pump();

    // 4. Verify Mobile Layout (List Only)
    expect(find.text('Activity Log'), findsOneWidget);
    expect(find.text('Healthy Plant'), findsOneWidget); // Only in master tile
    
    // Detail report should NOT be immediately visible in master view on mobile
    expect(find.text('Detailed Report'), findsNothing);
  });
}
