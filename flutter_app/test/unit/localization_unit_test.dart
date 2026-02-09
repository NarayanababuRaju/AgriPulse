import 'dart:io';
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

  tearDown(() async {
    await Hive.close();
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  group('LanguageNotifier Unit Tests', () {
    test('should have English as default language', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      
      expect(container.read(languageProvider), AppLanguage.en);
    });

    test('setLanguage should update state and persist to LocalVault', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(languageProvider.notifier);
      
      await notifier.setLanguage(AppLanguage.hi);
      expect(container.read(languageProvider), AppLanguage.hi);
      expect(LocalVault().getSavedLanguage(), 'hi');
    });

    test('translate should return correct values for English', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      
      final notifier = container.read(languageProvider.notifier);
      await notifier.setLanguage(AppLanguage.en);
      expect(notifier.translate('yield_prediction'), 'Yield Prediction');
      expect(notifier.translate('onion'), 'Onion');
    });

    test('translate should return correct values for Hindi', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      
      final notifier = container.read(languageProvider.notifier);
      await notifier.setLanguage(AppLanguage.hi);
      
      expect(notifier.translate('yield_prediction'), 'उपज भविष्यवाणी');
      expect(notifier.translate('onion'), 'प्याज');
    });

    test('translate should return correct values for Tamil', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      
      final notifier = container.read(languageProvider.notifier);
      await notifier.setLanguage(AppLanguage.ta);
      
      expect(notifier.translate('yield_prediction'), 'மகசூல் முன்னறிவிப்பு');
      expect(notifier.translate('onion'), 'வெங்காயம்');
    });

    test('translate should fallback to English for missing keys', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      
      final notifier = container.read(languageProvider.notifier);
      await notifier.setLanguage(AppLanguage.hi);
      
      // key_that_does_not_exist is not in any map, should return key itself
      expect(notifier.translate('key_that_does_not_exist'), 'key_that_does_not_exist');
    });
  });
}
