import 'dart:io';
import 'package:flutter/foundation.dart'; // For kIsWeb
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter_app/features/auth/providers/auth_provider.dart';

import '../../../core/theme/color_palette.dart';
import '../../../core/utils/error_handler.dart';
import '../providers/diagnosis_provider.dart';
import 'widgets/diagnosis_report_dialog.dart';

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
        final authState = ref.read(authStateProvider);
        final String languageCode = authState.value?.language ?? 'en';
        final String localeId = _mapLanguageToLocale(languageCode);
        
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

  String _mapLanguageToLocale(String code) {
    switch (code) {
      case 'hi': return 'hi_IN'; // Hindi
      case 'kn': return 'kn_IN'; // Kannada
      case 'te': return 'te_IN'; // Telugu
      case 'ta': return 'ta_IN'; // Tamil
      case 'ml': return 'ml_IN'; // Malayalam
      case 'mr': return 'mr_IN'; // Marathi
      case 'gu': return 'gu_IN'; // Gujarati
      case 'pa': return 'pa_IN'; // Punjabi
      default: return 'en_IN';   // Default to Indian English
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

    return Scaffold(
      backgroundColor: ColorPalette.offWhite,
      appBar: AppBar(
        title: const Text("Crop Doctor"),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ============================================
            // LEFT PANEL: Input & Actions (Flex 4)
            // ============================================
            Expanded(
              flex: 4,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    "Upload Crop Image",
                    style: TextStyle(
                      fontSize: 20, 
                      fontWeight: FontWeight.bold, 
                      color: ColorPalette.textPrimary
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    "Take a clear photo of the affected area",
                    style: TextStyle(fontSize: 14, color: ColorPalette.textSecondary),
                  ),
                  const SizedBox(height: 24),
                  
                  // MAIN AREA: Picker or Preview
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: diagnosisState.imageFile == null 
                              ? Colors.grey.withValues(alpha: 0.3) 
                              : ColorPalette.emeraldGreen,
                          width: 2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: diagnosisState.imageFile == null
                          ? _buildPicker(context, controller)
                          : _buildPreview(context, controller, diagnosisState),
                    ),
                  ),

                  const SizedBox(height: 16),
                  
                  // FARMER DESCRIPTION INPUT
                  TextFormField(
                    controller: _textController,
                    onChanged: (value) => controller.setDescription(value),
                    decoration: InputDecoration(
                      hintText: "Describe issue (e.g., in Tamil/Telugu/Malayalam/Kannada/Hindi)",
                      hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13),
                      filled: true,
                      fillColor: Colors.white,
                      prefixIcon: const Icon(Icons.translate, color: ColorPalette.textSecondary),
                      
                      // MIC BUTTON
                      suffixIcon: GestureDetector(
                        onTap: _listen,
                        child: Icon(
                          _isListening ? Icons.mic : Icons.mic_none,
                          color: _isListening ? Colors.red : ColorPalette.emeraldGreen,
                        ),
                      ),
                      
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(color: ColorPalette.emeraldGreen),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    ),
                    maxLines: 2,
                    style: const TextStyle(fontSize: 14),
                  ),
                  
                  const SizedBox(height: 16),

                  // ANALYZE BUTTON
                  SizedBox(
                    height: 56,
                    child: ElevatedButton(
                      onPressed: (diagnosisState.imageFile == null || diagnosisState.isAnalyzing)
                          ? null 
                          : () => controller.analyzeImage(),
                      style: ElevatedButton.styleFrom(
                          backgroundColor: ColorPalette.emeraldGreen,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                          ),
                          disabledBackgroundColor: Colors.grey.shade300,
                      ),
                      child: diagnosisState.isAnalyzing
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text(
                              "Analyze Crop",
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                    ),
                  ).animate().fadeIn(),
                ],
              ),
            ),
            
            const SizedBox(width: 32),
            
            // ============================================
            // RIGHT PANEL: Diagnosis Results (Flex 5)
            // ============================================
            Expanded(
              flex: 5,
              child: Container(
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
                child: diagnosisState.diagnosisResult == null
                  ? _buildResultPlaceholder()
                  : _buildResultContent(context, diagnosisState.diagnosisResult!, diagnosisState, controller),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Builds the Image Picker UI (Camera/Gallery buttons)
  Widget _buildPicker(BuildContext context, DiagnosisController controller) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
            Icons.add_a_photo_outlined, 
            size: 64, 
            color: ColorPalette.emeraldGreen.withValues(alpha: 0.5)
        ).animate().scale(duration: 500.ms, curve: Curves.bounceOut),
        
        const SizedBox(height: 24),
        
        const Text(
            "Upload Image",
            style: TextStyle(
                fontSize: 20, 
                fontWeight: FontWeight.bold, 
                color: ColorPalette.textPrimary
            ),
        ),
        const SizedBox(height: 8),
        const Text(
            "Supports: JPG, PNG",
            style: TextStyle(color: Colors.grey),
        ),
        
        const SizedBox(height: 48),

        // Action Buttons
        Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
                _buildOptionButton(
                    context, 
                    icon: Icons.camera_alt_rounded, 
                    label: "Camera",
                    onTap: () => controller.pickImage(ImageSource.camera),
                ),
                const SizedBox(width: 24),
                _buildOptionButton(
                    context, 
                    icon: Icons.photo_library_rounded, 
                    label: "Gallery",
                    onTap: () => controller.pickImage(ImageSource.gallery),
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
          borderRadius: BorderRadius.circular(16),
          child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              decoration: BoxDecoration(
                  color: ColorPalette.offWhite,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: ColorPalette.emeraldGreen.withValues(alpha: 0.2)),
              ),
              child: Column(
                  children: [
                      Icon(icon, color: ColorPalette.emeraldGreen, size: 32),
                      const SizedBox(height: 8),
                      Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
                  ],
              ),
          ),
      );
  }

  /// Builds the Image Preview UI
  Widget _buildPreview(BuildContext context, DiagnosisController controller, DiagnosisState state) {
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
                     child: const Center(
                         child: Column(
                             mainAxisSize: MainAxisSize.min,
                             children: [
                                 Text(
                                     "Analyzing Crop...",
                                     style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                                 ),
                                 SizedBox(height: 8),
                                 Text(
                                     "Identifying potential diseases",
                                     style: TextStyle(color: Colors.white70, fontSize: 14),
                                 ),
                             ],
                         ),
                     ),
                 ),
          ],
      ).animate().fadeIn();
  }
  /// Builds the placeholder for the Right Panel
  Widget _buildResultPlaceholder() {
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
          "Diagnosis Results",
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.grey.shade400,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          "Upload an image and click analyze\nto see detailed report here.",
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.grey.shade400),
        ),
      ],
    );
  }

  /// Builds the Result Content (Mock Data Visualization)
  Widget _buildResultContent(BuildContext context, Map<String, dynamic> result, DiagnosisState diagnosisState, DiagnosisController controller) {
    // Assuming structure: { 'disease': '...', 'confidence': 0.95, 'treatment': '...' }
    // Fallback values if keys are missing
    final disease = result['disease_name']?.toString() ?? "Unknown Issue"; // Adapted to likely API key
    final confidence = (result['confidence_score'] is num) ? result['confidence_score'] : 0.85;
    final treatment = result['treatment_recommendation']?.toString() ?? "Consult an expert.";

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Disease Name
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: ColorPalette.rustRed.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.warning_amber_rounded, color: ColorPalette.rustRed, size: 32),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Detected Issue",
                      style: TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                    Text(
                      disease,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: ColorPalette.rustRed,
                      ),
                    ),
                  ],
                ),
              ),
              // Confidence Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.green.shade200),
                ),
                child: Text(
                  "${(confidence * 100).toInt()}% Confidence",
                  style: TextStyle(
                    color: Colors.green.shade700,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          
          const Divider(height: 48),

          // Treatment Section
          const Text(
            "Recommended Treatment",
            style: TextStyle(
              fontSize: 18, 
              fontWeight: FontWeight.bold,
              color: ColorPalette.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: ColorPalette.offWhite,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                 const Icon(Icons.medical_services_outlined, color: ColorPalette.emeraldGreen, size: 24),
                 const SizedBox(width: 16),
                 Expanded(
                   child: Text(
                     treatment,
                     style: const TextStyle(
                       fontSize: 16,
                       height: 1.5,
                       color: ColorPalette.textPrimary,
                     ),
                   ),
                 ),
              ],
            ),
          ),

          const SizedBox(height: 24),
          
          // Audio / Voice
          InkWell(
            onTap: diagnosisState.isSynthesizing ? null : () => controller.playAdvice(),
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue.shade100),
              ),
              child: Row(
                children: [
                  Icon(Icons.volume_up_rounded, color: Colors.blue.shade700),
                  const SizedBox(width: 12),
                  Text(
                    diagnosisState.isSynthesizing 
                      ? "Getting audio..." 
                      : (diagnosisState.isAudioPlaying ? "Playing advice..." : "Listen to advice"),
                    style: TextStyle(
                      color: Colors.blue.shade700,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  if (diagnosisState.isSynthesizing)
                    const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.blue),
                    )
                  else
                    Icon(
                      diagnosisState.isAudioPlaying 
                        ? Icons.pause_circle_filled_rounded 
                        : Icons.play_circle_fill_rounded, 
                      color: Colors.blue.shade700, 
                      size: 32
                    ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // GENERATE REPORT BUTTON
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () {
                showDialog(
                  context: context, // Use the passed context or widget context
                  builder: (ctx) => DiagnosisReportDialog(
                    data: result,
                    farmerDescription: ref.read(diagnosisProvider).description,
                  ),
                );
              },
              icon: const Icon(Icons.summarize_outlined, color: ColorPalette.emeraldGreen),
              label: const Text(
                "Generate Report",
                style: TextStyle(color: ColorPalette.emeraldGreen, fontWeight: FontWeight.bold),
              ),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                side: const BorderSide(color: ColorPalette.emeraldGreen),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms, curve: Curves.easeOut);
  }
}
