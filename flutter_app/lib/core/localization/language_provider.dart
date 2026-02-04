import 'package:flutter_riverpod/flutter_riverpod.dart';
export 'app_language.dart';
import 'app_language.dart';
import 'maps/app_language_english.dart';
import 'maps/app_language_hindi.dart';
import 'maps/app_language_tamil.dart';
import 'maps/app_language_kannada.dart';
import 'maps/app_language_telugu.dart';
import 'maps/app_language_malayalam.dart';
import '../services/local_vault.dart';

class LanguageNotifier extends StateNotifier<AppLanguage> {
  LanguageNotifier() : super(AppLanguage.en) {
    _loadSavedLanguage();
  }

  /// Load saved language preference from LocalVault
  Future<void> _loadSavedLanguage() async {
    final savedCode = LocalVault().getSavedLanguage();
    if (savedCode != null) {
      state = AppLanguageExtension.fromCode(savedCode);
    }
  }

  /// Set language and persist to storage
  Future<void> setLanguage(AppLanguage lang) async {
    state = lang;
    await LocalVault().saveLanguage(lang.code);
  }

  String translate(String key) {
    return _translations[state]?[key] ?? _translations[AppLanguage.en]?[key] ?? key;
  }

  static const Map<AppLanguage, Map<String, String>> _translations = {
    AppLanguage.en: englishTranslations,
    AppLanguage.hi: hindiTranslations,
    AppLanguage.ta: tamilTranslations,
    AppLanguage.kn: kannadaTranslations,
    AppLanguage.te: teluguTranslations,
    AppLanguage.ml: malayalamTranslations,
  };
}

final languageProvider = StateNotifierProvider<LanguageNotifier, AppLanguage>((ref) {
  return LanguageNotifier();
});
