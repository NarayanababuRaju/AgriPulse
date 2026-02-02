import 'package:image_picker/image_picker.dart';
import 'package:just_audio/just_audio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_app/core/api/agri_pulse_service.dart';
import 'package:flutter_app/features/auth/providers/auth_provider.dart';
import 'package:flutter_app/features/dashboard/presentation/providers/weather_provider.dart';
import 'package:flutter/foundation.dart'; // For debugPrint
import '../../../core/services/local_vault.dart';
import '../models/diagnosis_record.dart';

/// Diagnosis State
/// 
/// Tracks the selected image, analysis status, and API results.
class DiagnosisState {
  final XFile? imageFile;
  final String? description;
  final bool isAnalyzing;
  final String? errorMessage;
  final bool isSynthesizing;
  final bool isAudioPlaying;
  final Map<String, dynamic>? diagnosisResult;

  const DiagnosisState({
    this.imageFile,
    this.description,
    this.isAnalyzing = false,
    this.isSynthesizing = false,
    this.isAudioPlaying = false,
    this.errorMessage,
    this.diagnosisResult,
  });

  DiagnosisState copyWith({
    XFile? imageFile,
    String? description,
    bool? isAnalyzing,
    bool? isSynthesizing,
    bool? isAudioPlaying,
    String? errorMessage,
    Map<String, dynamic>? diagnosisResult,
  }) {
    return DiagnosisState(
      imageFile: imageFile ?? this.imageFile,
      description: description ?? this.description,
      isAnalyzing: isAnalyzing ?? this.isAnalyzing,
      isSynthesizing: isSynthesizing ?? this.isSynthesizing,
      isAudioPlaying: isAudioPlaying ?? this.isAudioPlaying,
      errorMessage: errorMessage ?? this.errorMessage,
      diagnosisResult: diagnosisResult ?? this.diagnosisResult,
    );
  }
}

class DiagnosisController extends StateNotifier<DiagnosisState> {
  late final AudioPlayer _player;
  final AgriPulseService _apiService;
  final ImagePicker _picker;
  final Ref _ref;

  DiagnosisController(this._apiService, this._ref, {AudioPlayer? player, ImagePicker? picker}) 
      : _picker = picker ?? ImagePicker(),
        super(const DiagnosisState()) {
    _player = player ?? AudioPlayer();
    setupPlayer();
  }

  /// Pick an image from Camera or Gallery
  Future<void> pickImage(ImageSource source) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85, // Optimize for upload
      );

      if (pickedFile != null) {
        // Reset result when new image picked
        state = state.copyWith(
          imageFile: pickedFile, 
          errorMessage: null, 
          diagnosisResult: null
        );
      }
    } catch (e) {
      state = state.copyWith(errorMessage: "Failed to pick image: $e");
    }
  }

  /// Update the farmer's description of the issue
  void setDescription(String text) {
    state = state.copyWith(description: text);
  }

  /// Analyze the selected image using Gemini 3 Backend
  Future<void> analyzeImage() async {
    if (state.imageFile == null) return;

    state = state.copyWith(isAnalyzing: true, errorMessage: null);

    try {
      // Get user language for consistency
      final authState = _ref.read(authStateProvider);
      final String languageCode = authState.value?.language ?? 'en-IN';

      // Get weather context if available
      final weatherState = _ref.read(weatherProvider);
      final weatherContext = weatherState.data;

      final result = await _apiService.analyzeCrop(
        state.imageFile!, 
        "demo-farmer-123", // Hardcoded for MVP
        state.description ?? "",
        languageCode: languageCode,
        weatherContext: weatherContext,
      );
      
      final record = DiagnosisRecord(
        id: result['analysis_id'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
        imagePath: state.imageFile!.path,
        diseaseName: result['disease_name'] ?? 'Unknown',
        confidence: (result['confidence_score'] ?? 0.0).toDouble(),
        treatmentSummary: result['treatment_recommendation'] ?? '',
        timestamp: DateTime.now(),
        farmerInput: state.description,
        refinementReasoning: result['refinement_reasoning'], // available if refined
        treatmentAdjustment: result['treatment_adjustment'],
      );
      
      await LocalVault().saveDiagnosis(record);

      state = state.copyWith(
        isAnalyzing: false,
        diagnosisResult: result,
      );
    } catch (e) {
      state = state.copyWith(
        isAnalyzing: false,
        errorMessage: e.toString().contains("API Error") 
            ? e.toString().replaceAll("Exception: ", "") 
            : "Analysis failed. connection error.",
      );
    }
  }

  /// Translate the current diagnosis result
  Future<void> translateDiagnosis(String languageName) async {
    if (state.diagnosisResult == null) return;
    
    // Don't show full loading spinner, maybe just a smaller indicator or reuse analyzing?
    // Re-using isAnalyzing might be confusing if it shows "Analyzing Crop...". 
    // Ideally we add isTranslating, but for MVP let's just do it silently or reuse isAnalyzing with a different UI check?
    // Let's reuse isAnalyzing but we need to arguably prevent the "Analyzing Crop" overlay if possible, or just accept it.
    // Actually, the UI shows the overlay if isAnalyzing is true. That's fine, "Refining..."
    state = state.copyWith(isAnalyzing: true);

    try {
      final currentResult = state.diagnosisResult!;
      final disease = currentResult['disease_name'] ?? '';
      final treatment = currentResult['treatment_recommendation'] ?? '';
      final prevention = (currentResult['prevention'] as List?)?.join(' . ') ?? '';

      // Format: "DISEASE_START...DISEASE_END..."
      final fullText = """
DISEASE_START
$disease
DISEASE_END
TREATMENT_START
$treatment
TREATMENT_END
PREVENTION_START
$prevention
PREVENTION_END
""";

      final translatedBlock = await _apiService.translateText(fullText, languageName);

      // Parse
      final diseaseMatch = RegExp(r'DISEASE_START\n(.*?)\nDISEASE_END', dotAll: true).firstMatch(translatedBlock);
      final treatmentMatch = RegExp(r'TREATMENT_START\n(.*?)\nTREATMENT_END', dotAll: true).firstMatch(translatedBlock);
      final preventionMatch = RegExp(r'PREVENTION_START\n(.*?)\nPREVENTION_END', dotAll: true).firstMatch(translatedBlock);
      
      final newDisease = diseaseMatch?.group(1)?.trim() ?? disease;
      final newTreatment = treatmentMatch?.group(1)?.trim() ?? treatment;
      final preventionText = preventionMatch?.group(1)?.trim();
      final newPrevention = preventionText != null ? preventionText.split(' . ') : (currentResult['prevention'] as List?);

      final newResult = Map<String, dynamic>.from(currentResult);
      newResult['disease_name'] = newDisease;
      newResult['treatment_recommendation'] = newTreatment;
      newResult['prevention'] = newPrevention;

      state = state.copyWith(isAnalyzing: false, diagnosisResult: newResult);
    } catch (e) {
      debugPrint("Diagnosis Translation Error: $e");
      state = state.copyWith(isAnalyzing: false);
    }
  }

  /// Refine the diagnosis based on user feedback
  Future<void> refineDiagnosis(String feedback, Map<String, dynamic> overrides) async {
    if (state.diagnosisResult == null) return;
    
    state = state.copyWith(isAnalyzing: true, errorMessage: null);

    try {
      final authState = _ref.read(authStateProvider);
      final String languageCode = authState.value?.language ?? 'en-IN';

      final result = await _apiService.refineDiagnosis(
        farmerId: "demo-farmer-123",
        originalDiagnosis: state.diagnosisResult!,
        feedback: feedback,
        contextOverrides: overrides,
        language: languageCode,
      );

      final refinementData = result['result'];
      
      // Merge refinement into existing result to preserve UI structure
      final currentResult = Map<String, dynamic>.from(state.diagnosisResult!);
      
      if (refinementData['is_revised'] == true) {
        currentResult['disease_name'] = refinementData['revised_diagnosis'];
        currentResult['confidence_score'] = refinementData['confidence_score'];
      }
      
      // Always add reasoning and adjustment
      currentResult['refinement_reasoning'] = refinementData['reasoning'];
      currentResult['treatment_adjustment'] = refinementData['treatment_adjustment'];
      
      // If there's a treatment adjustment, append it to recommendation
      if (refinementData['treatment_adjustment'] != null && 
          refinementData['treatment_adjustment'].toString().isNotEmpty) {
        String currentTreat = currentResult['treatment_recommendation'] ?? "";
        currentResult['treatment_recommendation'] = "$currentTreat\n\n[Adjustment]: ${refinementData['treatment_adjustment']}";
      }

      // Save refined record to history
      final record = DiagnosisRecord(
        id: currentResult['analysis_id'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
        imagePath: state.imageFile!.path,
        diseaseName: currentResult['disease_name'] ?? 'Unknown',
        confidence: (currentResult['confidence_score'] ?? 0.0).toDouble(),
        treatmentSummary: currentResult['treatment_recommendation'] ?? '',
        timestamp: DateTime.now(),
        farmerInput: feedback,
        refinementReasoning: currentResult['refinement_reasoning'],
        treatmentAdjustment: refinementData['treatment_adjustment'],
      );
      await LocalVault().saveDiagnosis(record);

      state = state.copyWith(
        isAnalyzing: false,
        diagnosisResult: currentResult,
      );
    } catch (e) {
      state = state.copyWith(
        isAnalyzing: false,
        errorMessage: "Refinement failed: ${e.toString()}",
      );
    }
  }

  /// Clear the selected image and results
  void clearImage() {
    _player.stop();
    state = const DiagnosisState();
  }

  void setupPlayer() {
    _player.playerStateStream.listen((pState) {
      debugPrint("TTS: Player State -> ${pState.processingState}");
      if (pState.processingState == ProcessingState.completed) {
        state = state.copyWith(isAudioPlaying: false);
      }
    });
  }

  /// Listen to Advice (TTS)
  Future<void> playAdvice() async {
    if (state.diagnosisResult == null || state.isSynthesizing) return;
    
    if (state.isAudioPlaying) {
      await _player.pause();
      state = state.copyWith(isAudioPlaying: false);
      return;
    }

    final treatment = state.diagnosisResult!['treatment_recommendation'] ?? "No advice available.";
    final disease = state.diagnosisResult!['disease_name'] ?? "Unknown issue";
    final textToSpeak = "Diagnosis: $disease. Recommendation: $treatment";

    state = state.copyWith(isSynthesizing: true, errorMessage: null);

    try {
      // Get user language for TTS
      final authState = _ref.read(authStateProvider);
      final String languageCode = authState.value?.language ?? 'en-IN';
      
      final audioBytes = await _apiService.synthesizeSpeech(textToSpeak, languageCode);
      debugPrint("TTS: Received ${audioBytes.length} bytes");
      
      if (audioBytes.isEmpty) {
        throw Exception("Received empty audio bytes from server.");
      }

      final dataUrl = Uri.dataFromBytes(audioBytes, mimeType: 'audio/mpeg').toString();
      await _player.setAudioSource(AudioSource.uri(Uri.parse(dataUrl)));
      
      _player.play();
      debugPrint("TTS: play() instruction sent");
      state = state.copyWith(isSynthesizing: false, isAudioPlaying: true);
    } catch (e) {
      debugPrint("TTS Error in playAdvice: $e");
      state = state.copyWith(
        isSynthesizing: false,
        errorMessage: "Failed to play advice: $e",
      );
    }
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }
}

/// Provider
final diagnosisProvider = StateNotifierProvider.autoDispose<DiagnosisController, DiagnosisState>((ref) {
  final apiService = ref.watch(agriPulseServiceProvider);
  return DiagnosisController(apiService, ref);
});

/// Provider for Local History (Offline Capable)
final diagnosisHistoryProvider = FutureProvider.autoDispose<List<DiagnosisRecord>>((ref) async {
  // Since Hive is synchronous for reads, we can just return the list.
  // Using FutureProvider allows for loading states if we were to move to async storage later.
  return LocalVault().getHistory();
});
