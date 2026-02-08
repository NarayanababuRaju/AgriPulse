import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/color_palette.dart';
import '../../../../core/router/app_router.dart';
import '../../../profile/providers/profile_provider.dart';
import '../../../../core/localization/language_provider.dart';

class FieldSelector extends ConsumerWidget {
  const FieldSelector({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileState = ref.watch(profileProvider);
    ref.watch(languageProvider); // Watch the state to trigger rebuilds on language change
    final l10n = ref.read(languageProvider.notifier);

    if (profileState.fields.isEmpty) return const SizedBox.shrink();

    return SizedBox(
      height: 70, // Fixed height for compact cards
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        clipBehavior: Clip.none, // Allow shadows to overflow
        itemCount: profileState.fields.length + 1, // +1 for "Add New"
        separatorBuilder: (context, index) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          // 🟩 ADD NEW PLOT CARD (Last Item)
          if (index == profileState.fields.length) {
            return InkWell(
              onTap: () => context.push(AppRouter.fieldRegistrationPath),
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: ColorPalette.emeraldGreen, width: 1.5),
                  boxShadow: [
                    BoxShadow(
                      color: ColorPalette.emeraldGreen.withValues(alpha: 0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    const Icon(Icons.add_rounded, color: ColorPalette.emeraldGreen),
                    const SizedBox(width: 8),
                    Text(
                      l10n.translate('register_new_plot'),
                      style: GoogleFonts.outfit(
                        fontWeight: FontWeight.bold,
                        color: ColorPalette.emeraldGreen,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          // 🚜 EXISTING PLOT CARD
          final field = profileState.fields[index];
          final isSelected = field.id == profileState.selectedFieldId;
          final isUnassigned = isUnassignedKey(field.name);

          return InkWell(
            onTap: () => ref.read(profileProvider.notifier).selectField(field.id),
            borderRadius: BorderRadius.circular(16),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isSelected ? ColorPalette.emeraldGreen : Colors.grey.shade200,
                  width: isSelected ? 2 : 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Row(
                children: [
                   Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: isSelected ? ColorPalette.emeraldGreen.withValues(alpha: 0.3) : ColorPalette.emeraldGreen.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      isUnassigned ? Icons.history_edu_rounded : Icons.grass_rounded,
                      color: isSelected ? ColorPalette.emeraldGreen : ColorPalette.emeraldGreen,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                         isUnassignedKey(field.name) 
                            ? l10n.translate('unassigned_legacy_data')
                            : (field.name == 'Main Plot (North)' ? l10n.translate('main_plot_north') : field.name),
                        style: GoogleFonts.outfit(
                          fontWeight: FontWeight.bold,
                          color: isSelected ? ColorPalette.emeraldGreen : ColorPalette.textPrimary,
                          fontSize: 14,
                        ),
                      ),
                      if (!isUnassigned)
                        Text(
                          "${field.acreage} ${l10n.translate('acres')}",
                          style: GoogleFonts.outfit(
                            color: isSelected ? ColorPalette.emeraldGreen.withValues(alpha: 0.8) : ColorPalette.textSecondary,
                            fontSize: 11,
                          ),
                        ),
                    ],
                  ),
                  
                  // Delete Button - Show for all user-created plots
                  if (!isUnassigned) ...[
                    const SizedBox(width: 8),
                    InkWell(
                      onTap: () => _confirmDelete(
                        context, 
                        ref, 
                        field.id, 
                        field.name,
                        l10n,
                        isOnlyPlot: profileState.fields.length == 1,
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(4.0),
                        child: Icon(
                          Icons.delete_outline_rounded,
                          size: 18,
                          color: isSelected 
                            ? ColorPalette.rustRed.withValues(alpha: 0.6)
                            : Colors.grey.shade400,
                        ),
                      ),
                    ),
                  ]
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  bool isUnassignedKey(String? name) {
    return name == "Unassigned / Legacy Data" || name == "unassigned_field";
  }

  void _confirmDelete(
    BuildContext context, 
    WidgetRef ref, 
    String fieldId, 
    String plotName,
    dynamic l10n,
    {bool isOnlyPlot = false}
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              isOnlyPlot ? Icons.warning_amber_rounded : Icons.delete_outline_rounded,
              color: ColorPalette.rustRed,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                l10n.translate('delete_plot'),
                style: const TextStyle(fontSize: 18),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isOnlyPlot
                ? l10n.translate('delete_only_plot_warning')
                : l10n.translate('delete_plot_confirm'),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.grass_rounded, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      plotName,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
            if (isOnlyPlot) ...[
              const SizedBox(height: 12),
              Text(
                l10n.translate('redirect_to_setup_hint'),
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.translate('cancel')),
          ),
          TextButton(
            onPressed: () async {
              await ref.read(profileProvider.notifier).removeField(fieldId);
              if (context.mounted) {
                Navigator.pop(context);
                // If this was the only plot, router will auto-redirect to field registration
              }
            },
            child: Text(
              l10n.translate('delete'), 
              style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold)
            ),
          ),
        ],
      ),
    );
  }
}

