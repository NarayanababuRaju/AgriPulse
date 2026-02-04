enum AppLanguage { en, hi, ta, kn, te, ml }

extension AppLanguageExtension on AppLanguage {
  /// User-friendly name for display in settings/profile
  String get displayName {
    switch (this) {
      case AppLanguage.en: return "English";
      case AppLanguage.hi: return "हिन्दी (Hindi)";
      case AppLanguage.ta: return "தமிழ் (Tamil)";
      case AppLanguage.kn: return "ಕನ್ನಡ (Kannada)";
      case AppLanguage.te: return "తెలుగు (Telugu)";
      case AppLanguage.ml: return "മലയാളം (Malayalam)";
    }
  }

  /// Native name only (for compact display in language selector)
  String get nativeName {
    switch (this) {
      case AppLanguage.en: return "English";
      case AppLanguage.hi: return "हिन्दी";
      case AppLanguage.ta: return "தமிழ்";
      case AppLanguage.kn: return "ಕನ್ನಡ";
      case AppLanguage.te: return "తెలుగు";
      case AppLanguage.ml: return "മലയാളം";
    }
  }

  /// Canonical name used for backend AI translation requests
  String get backendName {
    switch (this) {
      case AppLanguage.en: return "English";
      case AppLanguage.hi: return "Hindi";
      case AppLanguage.ta: return "Tamil";
      case AppLanguage.kn: return "Kannada";
      case AppLanguage.te: return "Telugu";
      case AppLanguage.ml: return "Malayalam";
    }
  }

  /// Locale ID for speech-to-text recognition
  String get sttLocale {
    switch (this) {
      case AppLanguage.en: return "en_IN";
      case AppLanguage.hi: return "hi_IN";
      case AppLanguage.ta: return "ta_IN";
      case AppLanguage.kn: return "kn_IN";
      case AppLanguage.te: return "te_IN";
      case AppLanguage.ml: return "ml_IN";
    }
  }

  /// ISO 639-1 code
  String get code => name;

  /// Create AppLanguage from code string
  static AppLanguage fromCode(String code) {
    return AppLanguage.values.firstWhere(
      (lang) => lang.code == code,
      orElse: () => AppLanguage.en,
    );
  }
}
