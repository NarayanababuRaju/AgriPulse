import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../providers/profile_provider.dart';
import '../../../../core/theme/color_palette.dart';
import '../widgets/selection_card.dart';
import '../../domain/entities/soil_type.dart';
import 'package:flutter_app/core/localization/language_provider.dart';
import 'package:flutter_app/core/widgets/language_selector.dart';

class FarmSetupWizard extends ConsumerStatefulWidget {
  const FarmSetupWizard({super.key});

  @override
  ConsumerState<FarmSetupWizard> createState() => _FarmSetupWizardState();
}

class _FarmSetupWizardState extends ConsumerState<FarmSetupWizard> {
  int _currentStep = 0;
  final int _totalSteps = 3;

  final _nameController = TextEditingController();
  final _acreageController = TextEditingController();
  String _selectedSoilId = SoilType.defaults.first.id;
  String _selectedIrrigationKey = 'drip';

  @override
  void dispose() {
    _nameController.dispose();
    _acreageController.dispose();
    super.dispose();
  }

  void _nextStep() {
    if (_currentStep < _totalSteps - 1) {
      setState(() => _currentStep++);
    } else {
      _finish();
    }
  }

  void _prevStep() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
    }
  }

  Future<void> _finish() async {
    final soil = SoilType.defaults.firstWhere((s) => s.id == _selectedSoilId);
    final tr = ref.read(languageProvider.notifier);
    await ref.read(profileProvider.notifier).addField(
      name: _nameController.text.isEmpty ? tr.translate('my_first_plot') : _nameController.text,
      soilType: tr.translate(soil.nameKey),
      acreage: double.tryParse(_acreageController.text) ?? 1.0,
      irrigationType: tr.translate(_selectedIrrigationKey),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Watch language state to trigger rebuilds on language change
    ref.watch(languageProvider);
    final tr = ref.watch(languageProvider.notifier);
    
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: _currentStep > 0 
          ? IconButton(
              icon: const Icon(Icons.arrow_back, color: ColorPalette.textPrimary),
              onPressed: _prevStep,
            )
          : null,
        title: _StepIndicator(current: _currentStep, total: _totalSteps),
        centerTitle: true,
        actions: const [
          Center(
            child: LanguageSelector(
              textColor: ColorPalette.textPrimary,
            ),
          ),
          SizedBox(width: 16),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: _buildCurrentStep(tr),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _nextStep,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: ColorPalette.emeraldGreen,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: Text(
                    _currentStep == _totalSteps - 1 ? tr.translate('finish_setup') : tr.translate('continue'),
                    style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCurrentStep(LanguageNotifier tr) {
    switch (_currentStep) {
      case 0:
        return _WelcomeStep(
          tr: tr,
          nameController: _nameController,
          acreageController: _acreageController,
        );
      case 1:
        return _SoilStep(
          tr: tr,
          selectedId: _selectedSoilId,
          onSelect: (id) => setState(() => _selectedSoilId = id),
        );
      case 2:
        return _IrrigationStep(
          tr: tr,
          selected: _selectedIrrigationKey,
          onSelect: (val) => setState(() => _selectedIrrigationKey = val),
        );
      default:
        return const SizedBox.shrink();
    }
  }
}

class _StepIndicator extends StatelessWidget {
  final int current;
  final int total;

  const _StepIndicator({required this.current, required this.total});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 120,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: List.generate(total, (index) {
          return AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            height: 6,
            width: 32,
            decoration: BoxDecoration(
              color: index <= current ? ColorPalette.emeraldGreen : const Color(0xFFE5E7EB),
              borderRadius: BorderRadius.circular(3),
            ),
          );
        }),
      ),
    );
  }
}

class _WelcomeStep extends StatelessWidget {
  final LanguageNotifier tr;
  final TextEditingController nameController;
  final TextEditingController acreageController;

  const _WelcomeStep({
    required this.tr,
    required this.nameController,
    required this.acreageController,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(Icons.agriculture_rounded, size: 48, color: ColorPalette.emeraldGreen),
        const SizedBox(height: 16),
        Text(
          tr.translate('welcome_agripulse'),
          style: GoogleFonts.outfit(fontSize: 28, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text(
          tr.translate('setup_first_plot'),
          style: GoogleFonts.outfit(fontSize: 16, color: ColorPalette.textSecondary),
        ),
        const SizedBox(height: 32),
        Text(tr.translate('plot_name'), style: GoogleFonts.outfit(fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        TextField(
          controller: nameController,
          decoration: InputDecoration(
            hintText: "e.g., North Hillside",
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        const SizedBox(height: 24),
        Text(tr.translate('approx_acreage'), style: GoogleFonts.outfit(fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        TextField(
          controller: acreageController,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            hintText: "e.g., 2.5",
            suffixText: tr.translate('acres'),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
      ],
    );
  }
}

class _SoilStep extends StatelessWidget {
  final LanguageNotifier tr;
  final String selectedId;
  final Function(String) onSelect;

  const _SoilStep({
    required this.tr,
    required this.selectedId,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          tr.translate('soil_and_environment'),
          style: GoogleFonts.outfit(fontSize: 28, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text(
          tr.translate('help_gemini_understand'),
          style: GoogleFonts.outfit(fontSize: 16, color: ColorPalette.textSecondary),
        ),
        const SizedBox(height: 32),
        Text(
          tr.translate('select_soil_texture'),
          style: GoogleFonts.outfit(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: ColorPalette.textSecondary,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 16),
        ...SoilType.defaults.map((soil) => SelectionCard(
          title: tr.translate(soil.nameKey),
          subtitle: tr.translate(soil.localNameKey),
          description: tr.translate(soil.descriptionKey),
          icon: soil.icon,
          isSelected: selectedId == soil.id,
          onTap: () => onSelect(soil.id),
        )),
      ],
    );
  }
}

class _IrrigationStep extends StatelessWidget {
  final LanguageNotifier tr;
  final String selected;
  final Function(String) onSelect;

  const _IrrigationStep({
    required this.tr,
    required this.selected,
    required this.onSelect,
  });

  final List<String> _types = const [
    'drip', 'sprinkler', 'manual_bucket', 'flood', 'rain_fed'
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          tr.translate('irrigation_method'),
          style: GoogleFonts.outfit(fontSize: 28, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text(
          tr.translate('how_do_you_water'),
          style: GoogleFonts.outfit(fontSize: 16, color: ColorPalette.textSecondary),
        ),
        const SizedBox(height: 32),
        ..._types.map((key) => SelectionCard(
          title: tr.translate(key),
          icon: Icons.water_drop_rounded,
          isSelected: selected == key,
          onTap: () => onSelect(key),
        )),
      ],
    );
  }
}
