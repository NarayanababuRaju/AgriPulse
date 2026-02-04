import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import '../../providers/profile_provider.dart';
import '../../../../core/theme/color_palette.dart';
import '../../domain/entities/soil_type.dart';
import '../../domain/entities/plot_name_option.dart';
import '../../domain/entities/acreage_range_option.dart';
import 'package:flutter_app/core/localization/language_provider.dart';

class FieldRegistrationScreen extends ConsumerStatefulWidget {
  const FieldRegistrationScreen({super.key});

  @override
  ConsumerState<FieldRegistrationScreen> createState() => _FieldRegistrationScreenState();
}

class _FieldRegistrationScreenState extends ConsumerState<FieldRegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _customNameController = TextEditingController(); // Only for custom input
  final _customAcreageController = TextEditingController(); // Only for custom input
  
  String _selectedPlotNameId = PlotNameOption.defaults.first.id;
  String _selectedAcreageId = AcreageRangeOption.defaults.first.id;
  String _selectedSoilId = SoilType.defaults.first.id;
  String _selectedIrrigationKey = 'drip';

  final List<String> _irrigationKeys = [
    'drip',
    'sprinkler',
    'manual_bucket',
    'flood',
    'rain_fed',
  ];

  @override
  void dispose() {
    _customNameController.dispose();
    _customAcreageController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_formKey.currentState!.validate()) {
      final soil = SoilType.defaults.firstWhere((s) => s.id == _selectedSoilId);
      final plotNameOption = PlotNameOption.defaults.firstWhere((p) => p.id == _selectedPlotNameId);
      final acreageOption = AcreageRangeOption.defaults.firstWhere((a) => a.id == _selectedAcreageId);
      final tr = ref.read(languageProvider.notifier);
      
      // Determine plot name
      String plotName;
      if (_selectedPlotNameId == 'custom') {
        plotName = _customNameController.text;
      } else {
        plotName = tr.translate(plotNameOption.nameKey);
      }
      
      // Determine acreage value
      double acreageValue;
      if (_selectedAcreageId == 'custom') {
        acreageValue = double.parse(_customAcreageController.text);
      } else {
        acreageValue = acreageOption.midpoint;
      }
      
      await ref.read(profileProvider.notifier).addField(
        name: plotName,
        soilType: tr.translate(soil.nameKey),
        acreage: acreageValue,
        irrigationType: tr.translate(_selectedIrrigationKey),
      );
      if (mounted) context.pop(); // Returns to Dashboard
    }
  }

  @override
  Widget build(BuildContext context) {
    final tr = ref.watch(languageProvider.notifier);
    
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          tr.translate('register_new_plot'),
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        foregroundColor: ColorPalette.textPrimary,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                tr.translate('plot_info'),
                style: GoogleFonts.outfit(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: ColorPalette.emeraldGreen,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                tr.translate('ground_advice_hint'),
                style: GoogleFonts.outfit(
                  fontSize: 14,
                  color: ColorPalette.textSecondary,
                ),
              ),
              const SizedBox(height: 32),

              // Plot Name Selection - Interactive Cards
              Text(
                tr.translate('plot_name'),
                style: GoogleFonts.outfit(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: ColorPalette.textSecondary,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 12),
              
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: PlotNameOption.defaults.map((plotName) {
                  final isSelected = _selectedPlotNameId == plotName.id;
                  return InkWell(
                    onTap: () => setState(() => _selectedPlotNameId = plotName.id),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: isSelected ? ColorPalette.emeraldGreen : Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected ? ColorPalette.emeraldGreen : Colors.grey.shade300,
                          width: isSelected ? 2 : 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            plotName.icon,
                            size: 18,
                            color: isSelected ? Colors.white : ColorPalette.emeraldGreen,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            tr.translate(plotName.nameKey),
                            style: GoogleFonts.outfit(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: isSelected ? Colors.white : ColorPalette.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
              
              // Custom Plot Name Input (conditionally shown)
              if (_selectedPlotNameId == 'custom') ...[
                const SizedBox(height: 12),
                TextFormField(
                  controller: _customNameController,
                  decoration: InputDecoration(
                    hintText: "e.g., Rice Field 1",
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    prefixIcon: const Icon(Icons.edit_rounded),
                  ),
                  validator: (value) => (value == null || value.isEmpty) ? "Please enter a custom name" : null,
                ),
              ],
              
              const SizedBox(height: 24),

              // Acreage Selection - Interactive Cards
              Text(
                tr.translate('approx_acreage'),
                style: GoogleFonts.outfit(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: ColorPalette.textSecondary,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 12),
              
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: AcreageRangeOption.defaults.map((acreage) {
                  final isSelected = _selectedAcreageId == acreage.id;
                  return InkWell(
                    onTap: () => setState(() => _selectedAcreageId = acreage.id),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: isSelected ? ColorPalette.emeraldGreen : Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected ? ColorPalette.emeraldGreen : Colors.grey.shade300,
                          width: isSelected ? 2 : 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            acreage.icon,
                            size: 18,
                            color: isSelected ? Colors.white : ColorPalette.emeraldGreen,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            tr.translate(acreage.labelKey),
                            style: GoogleFonts.outfit(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: isSelected ? Colors.white : ColorPalette.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
              
              // Custom Acreage Input (conditionally shown)
              if (_selectedAcreageId == 'custom') ...[
                const SizedBox(height: 12),
                TextFormField(
                  controller: _customAcreageController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    hintText: "e.g., 2.5",
                    suffixText: tr.translate('acres'),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    prefixIcon: const Icon(Icons.straighten_rounded),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) return "Please enter acreage";
                    if (double.tryParse(value) == null) return "Enter a valid number";
                    return null;
                  },
                ),
              ],
              
              const SizedBox(height: 24),

              // Soil Selection - Compact Cards
              Text(
                tr.translate('select_soil_texture'),
                style: GoogleFonts.outfit(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: ColorPalette.textSecondary,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 12),
              
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: SoilType.defaults.map((soil) {
                  final isSelected = _selectedSoilId == soil.id;
                  return InkWell(
                    onTap: () => setState(() => _selectedSoilId = soil.id),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: isSelected ? ColorPalette.emeraldGreen : Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected ? ColorPalette.emeraldGreen : Colors.grey.shade300,
                          width: isSelected ? 2 : 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            soil.icon,
                            size: 18,
                            color: isSelected ? Colors.white : ColorPalette.emeraldGreen,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            tr.translate(soil.nameKey),
                            style: GoogleFonts.outfit(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: isSelected ? Colors.white : ColorPalette.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
              
              const SizedBox(height: 24),
              
              // Irrigation - Compact Cards
              Text(
                tr.translate('irrigation_method'),
                style: GoogleFonts.outfit(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: ColorPalette.textSecondary,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 12),
              
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _irrigationKeys.map((key) {
                  final isSelected = _selectedIrrigationKey == key;
                  return InkWell(
                    onTap: () => setState(() => _selectedIrrigationKey = key),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: isSelected ? ColorPalette.emeraldGreen : Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected ? ColorPalette.emeraldGreen : Colors.grey.shade300,
                          width: isSelected ? 2 : 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _getIrrigationIcon(key),
                            size: 18,
                            color: isSelected ? Colors.white : ColorPalette.emeraldGreen,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            tr.translate(key),
                            style: GoogleFonts.outfit(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: isSelected ? Colors.white : ColorPalette.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
              
              const SizedBox(height: 48),

              // Submit Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: ColorPalette.emeraldGreen,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: Text(
                    tr.translate('submit_registration'),
                    style: GoogleFonts.outfit(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getIrrigationIcon(String key) {
    switch (key) {
      case 'drip':
        return Icons.water_drop_rounded;
      case 'sprinkler':
        return Icons.shower_rounded;
      case 'manual_bucket':
        return Icons.shopping_basket_rounded;
      case 'flood':
        return Icons.waves_rounded;
      case 'rain_fed':
        return Icons.cloud_queue_rounded;
      default:
        return Icons.water_damage_rounded;
    }
  }
}
