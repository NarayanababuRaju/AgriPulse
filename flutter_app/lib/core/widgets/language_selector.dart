import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../localization/language_provider.dart';
import '../theme/color_palette.dart';

/// Compact language selector widget for displaying and changing the app language
class LanguageSelector extends ConsumerWidget {
  final bool showLabel;
  final Color? textColor;
  final Color? iconColor;
  final Function(AppLanguage)? onChanged;
  
  const LanguageSelector({
    super.key,
    this.showLabel = true,
    this.textColor,
    this.iconColor,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentLang = ref.watch(languageProvider);
    final isLight = textColor != null && textColor!.computeLuminance() < 0.5;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: isLight ? Colors.white : Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isLight ? Colors.grey.shade200 : Colors.white.withValues(alpha: 0.3),
          width: 1,
        ),
        boxShadow: isLight ? [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ] : null,
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<AppLanguage>(
          value: currentLang,
          isDense: true,
          icon: Icon(
            Icons.language_rounded,
            color: iconColor ?? (isLight ? ColorPalette.emeraldGreen : Colors.white),
            size: 18,
          ),
          dropdownColor: isLight ? Colors.white : ColorPalette.emeraldGreen,
          items: AppLanguage.values.map((AppLanguage lang) {
            return DropdownMenuItem<AppLanguage>(
              value: lang,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    '🇮🇳',
                    style: TextStyle(fontSize: 14),
                  ),
                  if (showLabel) ...[
                    const SizedBox(width: 8),
                    Text(
                      lang.nativeName,
                      style: TextStyle(
                        color: isLight ? ColorPalette.textPrimary : Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ],
              ),
            );
          }).toList(),
          onChanged: (AppLanguage? lang) {
            if (lang != null) {
              ref.read(languageProvider.notifier).setLanguage(lang);
              onChanged?.call(lang);
            }
          },
        ),
      ),
    );
  }
}
