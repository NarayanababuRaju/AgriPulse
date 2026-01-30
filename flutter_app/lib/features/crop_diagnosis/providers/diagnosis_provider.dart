import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_app/core/api/agri_pulse_service.dart';

/// Diagnosis State
/// 
/// Tracks the selected image, analysis status, and API results.
class DiagnosisState {
  final XFile? imageFile;
  final String? description; // Farmer's explanation in local language
  final bool isAnalyzing;
  final String? errorMessage;
  final Map<String, dynamic>? diagnosisResult;

  const DiagnosisState({
    this.imageFile,
    this.description,
    this.isAnalyzing = false,
    this.errorMessage,
    this.diagnosisResult,
  });

  DiagnosisState copyWith({
    XFile? imageFile,
    String? description,
    bool? isAnalyzing,
    String? errorMessage,
    Map<String, dynamic>? diagnosisResult,
  }) {
    return DiagnosisState(
      imageFile: imageFile ?? this.imageFile,
      description: description ?? this.description,
      isAnalyzing: isAnalyzing ?? this.isAnalyzing,
      errorMessage: errorMessage ?? this.errorMessage,
      diagnosisResult: diagnosisResult ?? this.diagnosisResult,
    );
  }
}

/// Diagnosis Controller
/// 
/// Manages picking images and sending them to the backend for analysis.
class DiagnosisController extends StateNotifier<DiagnosisState> {
  final AgriPulseService _apiService;
  final ImagePicker _picker = ImagePicker();

  DiagnosisController(this._apiService) : super(const DiagnosisState());

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
      final result = await _apiService.analyzeCrop(state.imageFile!);
      
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

  /// Clear the selected image and results
  void clearImage() {
    state = const DiagnosisState();
  }
}

/// Provider
final diagnosisProvider = StateNotifierProvider.autoDispose<DiagnosisController, DiagnosisState>((ref) {
  final apiService = ref.watch(agriPulseServiceProvider);
  return DiagnosisController(apiService);
});
