import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter_app/core/services/local_vault.dart';
import 'package:flutter_app/core/localization/language_provider.dart';


void main() {
  late Directory tempDir;

  setUp(() async {
    tempDir = Directory.systemTemp.createTempSync();
    Hive.init(tempDir.path);
    await LocalVault().init();
  });

  tearDown(() {
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  testWidgets('UI should update when language is changed', (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: Consumer(
              builder: (context, ref, _) {
                ref.watch(languageProvider);
                final tr = ref.read(languageProvider.notifier);
                return Column(
                  children: [
                    Text(tr.translate('yield_prediction')),
                    ElevatedButton(
                      key: const Key('switch_to_hi'),
                      onPressed: () => ref.read(languageProvider.notifier).setLanguage(AppLanguage.hi),
                      child: const Text('Switch to Hindi'),
                    ),
                    ElevatedButton(
                      key: const Key('switch_to_ta'),
                      onPressed: () => ref.read(languageProvider.notifier).setLanguage(AppLanguage.ta),
                      child: const Text('Switch to Tamil'),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );

    // 1. Initial English state
    expect(find.text('Yield Prediction'), findsOneWidget);

    // 2. Switch to Hindi
    await tester.tap(find.byKey(const Key('switch_to_hi')));
    await tester.pumpAndSettle();
    
    expect(find.text('उपज भविष्यवाणी'), findsOneWidget);
    expect(find.text('Yield Prediction'), findsNothing);

    // 3. Switch to Tamil
    await tester.tap(find.byKey(const Key('switch_to_ta')));
    await tester.pumpAndSettle();
    
    expect(find.text('மகசூல் முன்னறிவிப்பு'), findsOneWidget);
    expect(find.text('उपज भविष्यवाणी'), findsNothing);
  });
}
