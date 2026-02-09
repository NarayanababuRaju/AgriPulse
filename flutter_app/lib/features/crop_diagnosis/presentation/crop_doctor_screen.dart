import 'dart:io';
import 'package:flutter/foundation.dart'; // For kIsWeb
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:google_fonts/google_fonts.dart'; // Added for GoogleFonts

import '../../../core/theme/color_palette.dart';
import '../../../core/utils/error_handler.dart';
import '../providers/diagnosis_provider.dart';
import 'widgets/diagnosis_header_card.dart';
import 'widgets/diagnosis_report_dialog.dart';
import 'widgets/recursive_insight_thread.dart';
import 'package:flutter_app/core/localization/language_provider.dart';
import 'package:flutter_app/core/widgets/language_selector.dart';

/// Crop Doctor Screen
/// 
/// The main interface for the Diagnosis feature.
/// Toggles between "Empty State" (Pick Image) and "Preview State" (Analyze).
class CropDoctorScreen extends ConsumerStatefulWidget {
  const CropDoctorScreen({super.key});

  @override
  ConsumerState<CropDoctorScreen> createState() => _CropDoctorScreenState();
}

class _CropDoctorScreenState extends ConsumerState<CropDoctorScreen> {
  late stt.SpeechToText _speech;
  bool _isListening = false;
  final TextEditingController _textController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _speech = stt.SpeechToText();
    _initSpeech();
  }

  void _initSpeech() async {
    // Ideally check permissions here, but speech_to_text handles initialization gracefully
    await _speech.initialize();
    setState(() {});
  }

// ... (rest of imports)

// ...

  void _listen() async {
    if (!_isListening) {
      bool available = await _speech.initialize(
        onStatus: (val) => debugPrint('onStatus: $val'),
        onError: (val) => debugPrint('onError: $val'),
      );
      if (available) {
        setState(() => _isListening = true);
        
        // Get user's preferred language
        final language = ref.read(languageProvider);
        final String localeId = language.sttLocale;
        
        debugPrint("Listening in locale: $localeId");

        _speech.listen(
          onResult: (val) {
            setState(() {
              _textController.text = val.recognizedWords;
              // Update global state as well
              ref.read(diagnosisProvider.notifier).setDescription(val.recognizedWords);
            });
          },
          localeId: localeId, 
        );
      }
    } else {
      setState(() => _isListening = false);
      _speech.stop();
    }
  }


  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final diagnosisState = ref.watch(diagnosisProvider);
    final controller = ref.read(diagnosisProvider.notifier);

    // Listen for errors
    ref.listen(diagnosisProvider, (previous, next) {
      // Handle Errors
      if (next.errorMessage != null && next.errorMessage != previous?.errorMessage) {
        ErrorHandler.showError(context, next.errorMessage!);
      }
    });

    ref.watch(languageProvider);
    final tr = ref.read(languageProvider.notifier).translate;

    return Scaffold(
      backgroundColor: ColorPalette.offWhite,
      appBar: AppBar(
        title: Text(
          tr('crop_doctor'),
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        foregroundColor: ColorPalette.textPrimary,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => context.pop(),
        ),
        actions: [
          Center(
            child: LanguageSelector(
              textColor: ColorPalette.textPrimary,
              onChanged: (lang) {
                // Trigger Smart Translation if result exists
                if (ref.read(diagnosisProvider).diagnosisResult != null) {
                  ref.read(diagnosisProvider.notifier).translateDiagnosis(lang.backendName);
                }
              },
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () {
              ref.read(diagnosisProvider.notifier).reset();
            },
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: Column(
        children: [
          // 1. Full-Width Branding Header
          const DiagnosisHeaderCard(),

          // 2. Main Area (Modular Split View)
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  if (constraints.maxWidth < 700) {
                    return SingleChildScrollView(
                      child: Column(
                        children: [
                          _buildLeftPanel(diagnosisState, controller, tr, isMobile: true),
                          const SizedBox(height: 24),
                          _buildRightPanel(diagnosisState, controller, tr, isMobile: true, context: context),
                        ],
                      ),
                    );
                  }

                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 1,
                        child: _buildLeftPanel(diagnosisState, controller, tr),
                      ),
                      const SizedBox(width: 32),
                      Expanded(
                        flex: 1,
                        child: _buildRightPanel(diagnosisState, controller, tr, context: context),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLeftPanel(DiagnosisState diagnosisState, DiagnosisController controller, String Function(String) tr, {bool isMobile = false}) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
        // Top Row/Column: Input Split
        if (isMobile)
          Column(
            children: [
              SizedBox(
                height: 320,
                child: _buildVideoImageInput(diagnosisState, controller, tr),
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 180,
                child: _buildVoicePanel(controller, tr),
              ),
            ],
          )
        else
          SizedBox(
            height: 280,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(child: _buildVideoImageInput(diagnosisState, controller, tr)),
                const SizedBox(width: 16),
                Expanded(child: _buildVoicePanel(controller, tr)),
              ],
            ),
          ),
        
        const SizedBox(height: 16),
        
        // Bottom Grid: Analysis Chips
        if (isMobile)
          Column(
            children: _buildAnalysisSections(diagnosisState, controller, tr),
          )
        else
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: Column(children: _buildAnalysisSections(diagnosisState, controller, tr).sublist(0, 4))),
              const SizedBox(width: 12),
              Expanded(child: Column(children: _buildAnalysisSections(diagnosisState, controller, tr).sublist(4))),
            ],
          ),

        if (diagnosisState.diagnosisResult == null) ...[
          const SizedBox(height: 16),
          _buildActionButtons(diagnosisState, controller, tr),
        ],
      ],
      ),
    );
  }

  List<Widget> _buildAnalysisSections(DiagnosisState state, DiagnosisController controller, String Function(String) tr) {
    return [
      _buildModularSection(
        title: tr('irrigation_stage'),
        icon: Icons.water_drop_outlined,
        child: _buildIrrigationChips(state, controller, tr),
      ),
      const SizedBox(height: 12),
      _buildModularSection(
        title: tr('leaf_texture'),
        icon: Icons.texture_outlined,
        child: _buildTextureChips(state, controller, tr),
      ),
      const SizedBox(height: 12),
      _buildModularSection(
        title: tr('soil_moisture'),
        icon: Icons.waves_outlined,
        child: _buildSoilChips(state, controller, tr),
      ),
      const SizedBox(height: 12),
      _buildModularSection(
        title: tr('weather_events'),
        icon: Icons.cloud_outlined,
        child: _buildWeatherChips(state, controller, tr),
      ),
      const SizedBox(height: 12),
      _buildModularSection(
        title: tr('odor_presence'),
        icon: Icons.air_outlined,
        child: _buildOdorChips(state, controller, tr),
      ),
      const SizedBox(height: 12),
      _buildModularSection(
        title: tr('spread_pattern'),
        icon: Icons.grid_view_outlined,
        child: _buildSpreadChips(state, controller, tr),
      ),
      const SizedBox(height: 12),
      _buildModularSection(
        title: tr('speed_of_spread'),
        icon: Icons.speed_outlined,
        child: _buildSpeedChipsChallenge(state, controller, tr),
      ),
      const SizedBox(height: 12),
      _buildModularSection(
        title: tr('intervention_log'),
        icon: Icons.history_edu_outlined,
        child: _buildInterventionChips(state, controller, tr),
      ),
    ];
  }

  Widget _buildVideoImageInput(DiagnosisState diagnosisState, DiagnosisController controller, String Function(String) tr) {
    return Column(
      children: [
        if (diagnosisState.imageFile == null)
          Padding(
            padding: const EdgeInsets.only(top: 16, bottom: 8),
            child: Text(
              tr('take_photo_instruction'),
              style: const TextStyle(
                fontSize: 14,
                color: ColorPalette.textSecondary,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        Expanded(
          child: diagnosisState.imageFile == null
              ? _buildPicker(context, controller, tr)
              : _buildPreview(context, controller, diagnosisState, tr),
        ),
      ],
    );
  }

  Widget _buildRightPanel(DiagnosisState diagnosisState, DiagnosisController controller, String Function(String) tr, {bool isMobile = false, required BuildContext context}) {
    final panelContent = Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: diagnosisState.isAnalyzing
        ? _buildAnalyzingPlaceholder(tr)
        : diagnosisState.diagnosisResult == null
        ? _buildResultPlaceholder(tr)
        : Column(
            children: [
              _buildTreatmentSummaryCard(context, ref, diagnosisState.diagnosisResult!, tr),
              const SizedBox(height: 16),
              if (isMobile)
                RecursiveInsightThread(thread: diagnosisState.conversationThread, physics: const NeverScrollableScrollPhysics(), shrinkWrap: true)
              else
                Expanded(
                  child: RecursiveInsightThread(thread: diagnosisState.conversationThread),
                ),
            ],
          ),
    );

    if (isMobile) {
      return panelContent;
    }

    return panelContent;
  }

  /// Builds the top-level voice and language panel
  Widget _buildVoicePanel(DiagnosisController controller, String Function(String) tr) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ColorPalette.offWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: ColorPalette.emeraldGreen.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.record_voice_over_outlined, color: ColorPalette.emeraldGreen, size: 18),
              const SizedBox(width: 12),
              Flexible(
                child: Text(
                  tr('describe_issue_hint').split('(').first.trim(), 
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: _listen,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _isListening ? Colors.red.withValues(alpha: 0.1) : ColorPalette.emeraldGreen.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _isListening ? Icons.mic : Icons.mic_none,
                    color: _isListening ? Colors.red : ColorPalette.emeraldGreen,
                    size: 20,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: TextFormField(
              controller: _textController,
              onChanged: (value) => controller.setDescription(value),
              decoration: InputDecoration(
                hintText: tr('describe_issue_hint'),
                hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13),
                border: InputBorder.none,
                contentPadding: EdgeInsets.zero,
              ),
              maxLines: null,
              expands: true,
              textAlignVertical: TextAlignVertical.top,
              style: const TextStyle(fontSize: 13, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }

  /// Builds the Analyze and Reset buttons for the top panel
  Widget _buildActionButtons(DiagnosisState state, DiagnosisController controller, String Function(String) tr) {
    final isInitial = state.diagnosisResult == null;
    
    return Column(
      children: [
        if (state.imageFile != null || !isInitial)
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              onPressed: state.isAnalyzing ? null : () async {
                if (isInitial) {
                  await controller.analyzeImage();
                } else {
                  // Second Opinion / Refine
                  final overrides = {
                    'leaf_texture': state.leafTexture,
                    'odor_presence': state.odorPresence,
                    'speed_of_spread': state.speedOfSpread,
                  };
                  await controller.refineDiagnosis(state.description ?? "", overrides);
                }

                // Clear input on success
                if (ref.read(diagnosisProvider).errorMessage == null) {
                  _textController.clear();
                  controller.setDescription('');
                }
              },
              icon: state.isAnalyzing
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : Icon(isInitial ? Icons.analytics_outlined : Icons.auto_awesome_outlined),
              style: ElevatedButton.styleFrom(
                backgroundColor: ColorPalette.emeraldGreen,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
              label: Text(
                state.isAnalyzing 
                  ? (isInitial ? tr('analyzing') : tr('refining'))
                  : (isInitial ? tr('analyze_crop') : tr('ask_second_opinion')), 
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)
              ),
            ),
          ),
      ],
    );
  }

  /// Builds the Image Picker UI (Camera/Gallery buttons)
  Widget _buildPicker(BuildContext context, DiagnosisController controller, String Function(String) tr) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
            Icons.add_a_photo_outlined, 
            size: 48, // Balanced size
            color: ColorPalette.emeraldGreen.withValues(alpha: 0.5)
        ).animate().scale(duration: 500.ms, curve: Curves.bounceOut),
        
        const SizedBox(height: 12),
        
        Text(
            tr('upload_image'),
            style: const TextStyle(
                fontSize: 18, 
                fontWeight: FontWeight.bold, 
                color: ColorPalette.textPrimary
            ),
        ),
        
        const SizedBox(height: 4),
        Text(
          tr('supports_formats'),
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade500,
          ),
        ),
        
        const SizedBox(height: 24),

        // Action Buttons
        Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
                Expanded(
                  child: _buildOptionButton(
                      context, 
                      icon: Icons.camera_alt_rounded, 
                      label: tr('camera'),
                      onTap: () => controller.pickImage(ImageSource.camera),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildOptionButton(
                      context, 
                      icon: Icons.photo_library_rounded, 
                      label: tr('gallery'),
                      onTap: () => controller.pickImage(ImageSource.gallery),
                  ),
                ),
            ],
        ),
      ],
    );
  }

  /// Helper for Camera/Gallery buttons
  Widget _buildOptionButton(BuildContext context, {required IconData icon, required String label, required VoidCallback onTap}) {
      return InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16), 
              decoration: BoxDecoration(
                  color: ColorPalette.offWhite,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: ColorPalette.emeraldGreen.withValues(alpha: 0.2)),
              ),
              child: Column( 
                  mainAxisSize: MainAxisSize.min,
                  children: [
                      Icon(icon, color: ColorPalette.emeraldGreen, size: 24), 
                      const SizedBox(height: 8),
                      Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                  ],
              ),
          ),
      );
  }

  /// Builds the Image Preview UI
  Widget _buildPreview(BuildContext context, DiagnosisController controller, DiagnosisState state, String Function(String) tr) {
      return Stack(
          fit: StackFit.expand,
          children: [
              // 1. The Image
              ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: kIsWeb
                    ? Image.network(state.imageFile!.path, fit: BoxFit.contain)
                    : Image.file(File(state.imageFile!.path), fit: BoxFit.contain),
              ),
              
              // 2. Clear Button (Top Right)
              if (!state.isAnalyzing)
                Positioned(
                    top: 16,
                    right: 16,
                    child: GestureDetector(
                        onTap: () => controller.clearImage(),
                        child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: const BoxDecoration(
                                color: Colors.black54,
                                shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.close, color: Colors.white, size: 20),
                        ),
                    ),
                ),
                
               // 3. Analyzing Overlay
               if (state.isAnalyzing)
                 Container(
                     decoration: BoxDecoration(
                         color: Colors.black.withValues(alpha: 0.6),
                         borderRadius: BorderRadius.circular(24),
                     ),
                     child: Center(
                         child: Column(
                             mainAxisSize: MainAxisSize.min,
                             children: [
                                 Text(
                                     tr('analyzing'),
                                     style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                                 ),
                                 const SizedBox(height: 4),
                                 Text(
                                     tr('identifying_diseases'),
                                     style: const TextStyle(color: Colors.white70, fontSize: 12),
                                 ),
                             ],
                         ),
                     ),
                 ),
          ],
      ).animate().fadeIn();
  }
  /// Builds the placeholder for the Right Panel
  Widget _buildResultPlaceholder(String Function(String) tr) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.analytics_outlined,
          size: 80,
          color: Colors.grey.shade300,
        ),
        const SizedBox(height: 16),
        Text(
          tr('diagnosis_results'),
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.grey.shade400,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          tr('diagnosis_placeholder'),
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.grey.shade400),
        ),
      ],
    );
  }

  /// Builds the loading placeholder during analysis
  Widget _buildAnalyzingPlaceholder(String Function(String) tr) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Pulsing AI Icon
        const Icon(
          Icons.auto_awesome,
          size: 80,
          color: ColorPalette.emeraldGreen,
        ).animate(onPlay: (controller) => controller.repeat(reverse: true))
         .scale(begin: const Offset(1, 1), end: const Offset(1.2, 1.2), duration: 1000.ms)
         .then()
         .shimmer(duration: 1200.ms, color: Colors.white.withValues(alpha: 0.5)),
        
        const SizedBox(height: 24),
        
        Text(
          tr('analyzing'), // e.g. "Gemini analyzing..."
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: ColorPalette.emeraldGreen,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          tr('identifying_diseases'), // e.g. "Identifying diseases and pests..."
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.grey.shade600),
        ),
      ],
    );
  }

  // ============================================
  // SIDEBAR MODULAR GRID HELPERS (Phase 20+)
  // ============================================

  Widget _buildTreatmentSummaryCard(BuildContext context, WidgetRef ref, Map<String, dynamic> result, String Function(String) tr) {
    final treatment = result['treatment_recommendation'] ?? tr('no_advice_available');
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: ColorPalette.emeraldGreen.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: ColorPalette.emeraldGreen.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.medical_services_outlined, color: ColorPalette.emeraldGreen),
              const SizedBox(width: 12),
              Text(
                tr('treatment_plan'),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: ColorPalette.emeraldGreen,
                ),
              ),
              const Spacer(),
              TextButton.icon(
                onPressed: () {
                   showDialog(
                    context: context,
                    builder: (ctx) {
                      final diagState = ref.read(diagnosisProvider);
                      // If there is more than one item in the thread, the first user message is initial, 
                      // and the latest description might be the refinement.
                      final thread = diagState.conversationThread;
                      String? initialDesc = diagState.description;
                      String? refinedDesc;
                      
                      if (thread.length > 1) {
                        // Find the first user message
                        final firstUser = thread.firstWhere((item) => item.role == 'user', orElse: () => thread.first);
                        initialDesc = firstUser.content;
                        // If current description is different from first user, it might be the refinement
                        if (diagState.description != initialDesc) {
                          refinedDesc = diagState.description;
                        }
                      }

                      return DiagnosisReportDialog(
                        data: result,
                        farmerDescription: initialDesc,
                        additionalDescription: refinedDesc,
                        thread: diagState.conversationThread,
                      );
                    },
                  );
                },
                icon: const Icon(Icons.visibility_outlined, size: 16),
                label: Text(tr('view_report')),
                style: TextButton.styleFrom(
                  foregroundColor: ColorPalette.emeraldGreen,
                  textStyle: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            treatment.replaceAll(RegExp(r'\*\*|__'), ''), // Simple markdown strip
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 14,
              color: ColorPalette.textPrimary,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }


  Widget _buildModularSection({
    required String title, 
    required IconData icon, 
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: ColorPalette.emeraldGreen),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title.toUpperCase(),
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: ColorPalette.textSecondary,
                    letterSpacing: 1.1,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          child,
        ],
      ),
    );
  }

  Widget _buildIrrigationChips(DiagnosisState state, DiagnosisController controller, String Function(String) tr) {
    final stageKeys = ['establishment', 'sprouting', 'leaf_dev', 'bulb_init', 'bulb_dev'];
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: stageKeys.map((key) => _buildChoiceChip(
        label: tr(key),
        isSelected: state.irrigationStage == key,
        onSelected: (val) => controller.setIrrigationStage(val ? key : null),
      )).toList(),
    );
  }

  Widget _buildSoilChips(DiagnosisState state, DiagnosisController controller, String Function(String) tr) {
    final keys = ['bone_dry', 'moist', 'waterlogged'];
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: keys.map((key) => _buildChoiceChip(
        label: tr(key),
        isSelected: state.soilMoisture == key,
        onSelected: (val) => controller.setSoilMoisture(val ? key : null),
      )).toList(),
    );
  }

  Widget _buildSpreadChips(DiagnosisState state, DiagnosisController controller, String Function(String) tr) {
    final keys = ['isolated', 'localized', 'field_wide'];
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: keys.map((key) => _buildChoiceChip(
        label: tr(key),
        isSelected: state.spreadPattern == key,
        onSelected: (val) => controller.setSpreadPattern(val ? key : null),
      )).toList(),
    );
  }

  Widget _buildWeatherChips(DiagnosisState state, DiagnosisController controller, String Function(String) tr) {
    final keys = ['frost', 'heavy_rain', 'drizzle', 'wind', 'too_hot'];
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: keys.map((key) => _buildChoiceChip(
        label: tr(key),
        isSelected: state.weatherEvent == key,
        onSelected: (val) => controller.setWeatherEvent(val ? key : null),
      )).toList(),
    );
  }

  Widget _buildInterventionChips(DiagnosisState state, DiagnosisController controller, String Function(String) tr) {
    final treatmentKeys = ['fert_organic', 'fert_npk', 'fungicide', 'insecticide'];
    final dosageKeys = ['low', 'medium', 'high'];
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: treatmentKeys.map((key) => _buildChoiceChip(
            label: tr(key),
            isSelected: state.lastTreatment == key,
            onSelected: (val) => controller.setLastTreatment(val ? key : null),
          )).toList(),
        ),
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 8.0),
          child: Divider(height: 1),
        ),
        Row(
          children: dosageKeys.map((key) => Expanded(
            child: Padding(
              padding: EdgeInsets.only(right: key == dosageKeys.last ? 0 : 4),
              child: _buildChoiceChip(
                label: tr(key),
                isSelected: state.dosage == key,
                onSelected: (val) => controller.setDosage(val ? key : null),
              ),
            ),
          )).toList(),
        ),
      ],
    );
  }

  Widget _buildTextureChips(DiagnosisState state, DiagnosisController controller, String Function(String) tr) {
    final keys = ['texture_brittle', 'texture_slimy', 'texture_rubbery'];
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: keys.map((key) => _buildChoiceChip(
        label: tr(key),
        isSelected: state.leafTexture == key,
        onSelected: (val) => controller.setLeafTexture(val ? key : null),
      )).toList(),
    );
  }

  Widget _buildOdorChips(DiagnosisState state, DiagnosisController controller, String Function(String) tr) {
    final keys = ['odor_foul', 'odor_none'];
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: keys.map((key) => _buildChoiceChip(
        label: tr(key),
        isSelected: state.odorPresence == key,
        onSelected: (val) => controller.setOdorPresence(val ? key : null),
      )).toList(),
    );
  }

  Widget _buildSpeedChipsChallenge(DiagnosisState state, DiagnosisController controller, String Function(String) tr) {
    final keys = ['spread_overnight', 'spread_slow'];
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: keys.map((key) => _buildChoiceChip(
        label: tr(key),
        isSelected: state.speedOfSpread == key,
        onSelected: (val) => controller.setSpeedOfSpread(val ? key : null),
      )).toList(),
    );
  }

  Widget _buildChoiceChip({
    required String label, 
    required bool isSelected, 
    required Function(bool) onSelected,
    bool isFullWidth = false,
  }) {
    final chip = ChoiceChip(
      label: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          color: isSelected ? Colors.white : ColorPalette.textPrimary,
        ),
      ),
      selected: isSelected,
      onSelected: onSelected,
      selectedColor: ColorPalette.emeraldGreen,
      backgroundColor: Colors.white,
      labelPadding: const EdgeInsets.symmetric(horizontal: 4),
      padding: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(
          color: isSelected ? ColorPalette.emeraldGreen : Colors.grey.shade200,
          width: 1,
        ),
      ),
      showCheckmark: false,
    );

    if (isFullWidth) {
      return SizedBox(width: double.infinity, child: chip);
    }
    return chip;
  }
}
