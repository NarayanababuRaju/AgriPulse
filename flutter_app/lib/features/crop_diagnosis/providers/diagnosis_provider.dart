import 'dart:convert';
import 'package:image_picker/image_picker.dart';
import 'package:just_audio/just_audio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_app/core/api/agri_pulse_service.dart';
import 'package:flutter_app/features/auth/providers/auth_provider.dart';
import 'package:flutter_app/features/dashboard/presentation/providers/weather_provider.dart';
import 'package:flutter_app/features/profile/providers/profile_provider.dart';
import 'package:flutter/foundation.dart'; // For debugPrint
import '../../../core/services/local_vault.dart';
import '../models/diagnosis_record.dart';
import '../models/thread_item.dart';
import '../../../core/localization/language_provider.dart';
import '../../../core/api/path_enforcer.dart';

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
  final String? irrigationStage;
  final String? soilMoisture;
  final String? weatherEvent;
  final String? spreadPattern;
  final String? lastTreatment;
  final String? dosage;
  final String? leafTexture;
  final String? odorPresence;
  final String? speedOfSpread;
  final List<ThreadItem> conversationThread;
  final String? activeRecordId;

  const DiagnosisState({
    this.imageFile,
    this.description,
    this.isAnalyzing = false,
    this.isSynthesizing = false,
    this.isAudioPlaying = false,
    this.errorMessage,
    this.diagnosisResult,
    this.irrigationStage,
    this.soilMoisture,
    this.weatherEvent,
    this.spreadPattern,
    this.lastTreatment,
    this.dosage,
    this.leafTexture,
    this.odorPresence,
    this.speedOfSpread,
    this.conversationThread = const [],
    this.activeRecordId,
  });

  DiagnosisState copyWith({
    XFile? imageFile,
    String? description,
    bool? isAnalyzing,
    bool? isSynthesizing,
    bool? isAudioPlaying,
    String? errorMessage,
    Map<String, dynamic>? diagnosisResult,
    String? irrigationStage,
    String? soilMoisture,
    String? weatherEvent,
    String? spreadPattern,
    String? lastTreatment,
    String? dosage,
    String? leafTexture,
    String? odorPresence,
    String? speedOfSpread,
    List<ThreadItem>? conversationThread,
    String? activeRecordId,
  }) {
    return DiagnosisState(
      imageFile: imageFile ?? this.imageFile,
      description: description ?? this.description,
      isAnalyzing: isAnalyzing ?? this.isAnalyzing,
      isSynthesizing: isSynthesizing ?? this.isSynthesizing,
      isAudioPlaying: isAudioPlaying ?? this.isAudioPlaying,
      errorMessage: errorMessage ?? this.errorMessage,
      diagnosisResult: diagnosisResult ?? this.diagnosisResult,
      irrigationStage: irrigationStage ?? this.irrigationStage,
      soilMoisture: soilMoisture ?? this.soilMoisture,
      weatherEvent: weatherEvent ?? this.weatherEvent,
      spreadPattern: spreadPattern ?? this.spreadPattern,
      lastTreatment: lastTreatment ?? this.lastTreatment,
      dosage: dosage ?? this.dosage,
      leafTexture: leafTexture ?? this.leafTexture,
      odorPresence: odorPresence ?? this.odorPresence,
      speedOfSpread: speedOfSpread ?? this.speedOfSpread,
      conversationThread: conversationThread ?? this.conversationThread,
      activeRecordId: activeRecordId ?? this.activeRecordId,
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
        XFile finalFile = pickedFile;
        
        // Web Persistence Fix: Convert to Base64 Data URI
        // Hive cannot persist blob: URLs across refreshes
        if (kIsWeb) {
          final bytes = await pickedFile.readAsBytes();
          final String base64Data = base64Encode(bytes);
          final String mimeType = pickedFile.mimeType ?? 'image/jpeg';
          final String dataUri = 'data:$mimeType;base64,$base64Data';
          finalFile = XFile(dataUri, mimeType: mimeType);
        }

        // Reset result and record ID when new image picked
        state = state.copyWith(
          imageFile: finalFile, 
          errorMessage: null, 
          diagnosisResult: null,
          activeRecordId: null, 
          conversationThread: [],
        );
      }
    } catch (e) {
      state = state.copyWith(errorMessage: "Failed to pick image: $e");
    }
  }

  /// Load a record into the active state for refinement
  void loadRecord(DiagnosisRecord record) {
    // 1. Synthesize thread if missing (Legacy Support/Self-Healing)
    List<ThreadItem> activeThread = record.thread ?? [];
    if (activeThread.isEmpty) {
      activeThread = [
        ThreadItem(
          role: 'user',
          content: record.farmerInput ?? 'No initial description',
          timestamp: record.timestamp,
        ),
        ThreadItem(
          role: 'ai',
          content: record.treatmentSummary,
          timestamp: record.timestamp,
          metadata: {
            'disease_name': record.diseaseName,
            'confidence_score': record.confidence,
          }
        )
      ];
    }
    
    state = state.copyWith(
      activeRecordId: record.id,
      imageFile: XFile(record.imagePath),
      diagnosisResult: {
        'disease_name': record.diseaseName,
        'confidence_score': record.confidence,
        'treatment_recommendation': record.treatmentSummary,
        'refinement_reasoning': record.refinementReasoning,
        'treatment_adjustment': record.treatmentAdjustment,
        'initial_user_input': record.initialUserInput,
        'initial_ai_response': record.initialAiResponse,
      },
      conversationThread: activeThread,
      description: record.farmerInput,
      irrigationStage: record.irrigationStage,
      soilMoisture: record.soilMoisture,
      weatherEvent: record.weatherEvent,
      spreadPattern: record.spreadPattern,
      lastTreatment: record.lastTreatment,
      dosage: record.dosage,
    );
  }

  /// Update the farmer's description of the issue
  void setDescription(String text) {
    state = state.copyWith(description: text);
  }

  void setIrrigationStage(String? value) => state = state.copyWith(irrigationStage: value);
  void setSoilMoisture(String? value) => state = state.copyWith(soilMoisture: value);
  void setWeatherEvent(String? value) => state = state.copyWith(weatherEvent: value);
  void setSpreadPattern(String? value) => state = state.copyWith(spreadPattern: value);
  void setLastTreatment(String? value) => state = state.copyWith(lastTreatment: value);
  void setDosage(String? value) => state = state.copyWith(dosage: value);
  void setLeafTexture(String? value) => state = state.copyWith(leafTexture: value);
  void setOdorPresence(String? value) => state = state.copyWith(odorPresence: value);
  void setSpeedOfSpread(String? value) => state = state.copyWith(speedOfSpread: value);

  /// Analyze the selected image using Gemini 3 Backend
  Future<void> analyzeImage() async {
    if (state.imageFile == null) return;

    state = state.copyWith(isAnalyzing: true, errorMessage: null);

    try {
      // Get user language for consistency
      final currentLanguage = _ref.read(languageProvider);
      final tr = _ref.read(languageProvider.notifier).translate;
      final String languageCode = currentLanguage.backendName;

      // Get weather context if available
      final weatherState = _ref.read(weatherProvider);
      final weatherContext = weatherState.data;

      final profileState = _ref.read(profileProvider);
      final activeField = profileState.selectedField;
      final activeCycleId = profileState.activeCycleId;

      final authState = _ref.read(authStateProvider);
      final farmerId = authState.value?.id ?? "anonymous_farmer";

      final resultData = await _apiService.analyzeCrop(
        state.imageFile!, 
        farmerId,
        state.description ?? "",
        languageCode: languageCode,
        weatherContext: weatherContext,
        irrigationStage: state.irrigationStage,
        soilMoisture: state.soilMoisture,
        weatherEvent: state.weatherEvent,
        spreadPattern: state.spreadPattern,
        lastTreatment: state.lastTreatment,
        dosage: state.dosage,
      );
      
      // The backend /analyze endpoint returns flattened fields, not wrapped in 'result'
      final result = resultData;
      
      // Seed initial input for extraction persistence
      final String safeDescription = (state.description != null && state.description!.trim().isNotEmpty)
          ? state.description!
          : tr('no_feedback_provided');
          
      result['initial_user_input'] = safeDescription;
      result['initial_ai_response'] = result['treatment_recommendation'] ?? result['disease_name'] ?? 'Unknown Issue';
      
      // Seed the conversation with both User request and initial AI diagnosis
      final initialThread = [
        ThreadItem(
          role: 'user',
          content: safeDescription,
          timestamp: DateTime.now(),
        ),
        ThreadItem(
          role: 'ai', 
          content: result['treatment_recommendation'] ?? result['disease_name'] ?? 'Unknown Issue',
          timestamp: DateTime.now(),
          metadata: result, 
        )
      ];
      
      final String recordId = result['analysis_id'] ?? DateTime.now().millisecondsSinceEpoch.toString();
      
      final record = DiagnosisRecord(
        id: recordId,
        imagePath: state.imageFile!.path,
        diseaseName: result['disease_name'] ?? 'Unknown',
        confidence: (result['confidence_score'] ?? 0.0).toDouble(),
        treatmentSummary: result['treatment_recommendation'] ?? '',
        timestamp: DateTime.now(),
        farmerInput: safeDescription, // Step 1 marker for non-thread records
        severity: result['severity'],
        temperature: result['temperature'],
        humidity: result['humidity'],
        languageCode: languageCode,
        irrigationStage: state.irrigationStage,
        soilMoisture: state.soilMoisture,
        weatherEvent: state.weatherEvent,
        spreadPattern: state.spreadPattern,
        lastTreatment: state.lastTreatment,
        dosage: state.dosage,
        cropName: activeField?.cropType ?? 'onion',
        initialUserInput: result['initial_user_input'],
        initialAiResponse: result['initial_ai_response'],
        thread: initialThread,
      );
      
      // Hierarchical Save
      if (activeField != null && activeCycleId != null) {
        final userId = authState.value?.id ?? "anonymous";
        await LocalVault().saveDiagnosis(
          record, 
          userId: userId,
          fieldId: activeField.id, 
          cycleId: activeCycleId
        );

        // Auto-Refresh: Invalidate history provider to update dashboard immediately
        _ref.invalidate(diagnosisHistoryProvider);
      }

      state = state.copyWith(
        isAnalyzing: false,
        diagnosisResult: result,
        conversationThread: initialThread,
        activeRecordId: recordId, // Pin the ID for future refinements
      );
    } catch (e) {
      final tr = _ref.read(languageProvider.notifier);
      state = state.copyWith(
        isAnalyzing: false,
        errorMessage: e.toString().contains("API Error") 
            ? e.toString().replaceAll("Exception: ", "") 
            : tr.translate("analysis_failed_connection"),
      );
    }
  }

  /// Translate the current diagnosis result
  Future<void> translateDiagnosis(String languageName, {String? recordId}) async {
    if (state.diagnosisResult == null && recordId == null) return;
    state = state.copyWith(isAnalyzing: true, activeRecordId: recordId ?? state.activeRecordId);

    try {
      final currentResult = state.diagnosisResult!;
      final disease = currentResult['disease_name'] ?? '';
      final treatment = currentResult['treatment_recommendation'] ?? '';
      final prevention = (currentResult['prevention'] as List?)?.join(' . ') ?? '';
      final reasoning = currentResult['refinement_reasoning'] ?? '';
      final adjustment = currentResult['treatment_adjustment'] ?? '';

      final fullText = """
      INSTRUCTION: Translate the following agricultural diagnosis into $languageName. 
      IMPORTANT: DO NOT translate or modify any text inside double brackets like [[TAG_NAME]]. Keep them exactly as they are.

      [[CROP_DISEASE]]
      $disease
      
      [[TREATMENT_PLAN]]
      $treatment
      
      [[PREVENTION_STEPS]]
      $prevention
      
      [[AI_REASONING]]
      $reasoning
      
      [[TREATMENT_ADJUSTMENT]]
      $adjustment
      """;

      final translatedBlock = await _apiService.translateText(fullText, languageName);
      final String translatedStr = translatedBlock.toString();

      String parseSection(String tag) {
        final lines = translatedStr.split("\n");
        int startIndex = lines.indexWhere((l) => l.contains(tag));
        if (startIndex == -1) return "";
        
        final result = <String>[];
        for (int i = startIndex + 1; i < lines.length; i++) {
          final line = lines[i].trim();
          if (line.isEmpty) continue;
          if (line.startsWith("[[") && line.endsWith("]]")) break; 
          result.add(line);
        }
        return result.join("\n");
      }

      final newDisease = parseSection("[[CROP_DISEASE]]").split("\n").first.trim();
      final newTreatment = parseSection("[[TREATMENT_PLAN]]");
      final newPreventionRaw = parseSection("[[PREVENTION_STEPS]]");
      final newPrevention = newPreventionRaw.isNotEmpty ? newPreventionRaw.split(' . ') : (currentResult['prevention'] as List?);
      final newReasoning = parseSection("[[AI_REASONING]]");
      final newAdjustment = parseSection("[[TREATMENT_ADJUSTMENT]]");

      final newResult = Map<String, dynamic>.from(currentResult);
      newResult['disease_name'] = newDisease.isNotEmpty ? newDisease : disease;
      newResult['treatment_recommendation'] = newTreatment.isNotEmpty ? newTreatment : treatment;
      newResult['prevention'] = newPrevention;
      newResult['refinement_reasoning'] = newReasoning.isNotEmpty ? newReasoning : reasoning;
      newResult['treatment_adjustment'] = newAdjustment.isNotEmpty ? newAdjustment : adjustment;

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
      final currentLanguage = _ref.read(languageProvider);
      final tr = _ref.read(languageProvider.notifier).translate;
      final String languageCode = currentLanguage.backendName;

      final profileState = _ref.read(profileProvider);
      final activeField = profileState.selectedField;
      
      final farmerId = authState.value?.id ?? "anonymous_farmer";

      // Enrich overrides with active plot context
      final enrichedOverrides = {
        ...overrides,
        'acreage': activeField?.acreage,
        'soil_type': activeField?.soilType,
      };

      // 1. Add User Feedback to Thread
      final userItem = ThreadItem(
        role: 'user',
        content: feedback,
        timestamp: DateTime.now(),
      );
      
      final currentThread = List<ThreadItem>.from(state.conversationThread)..add(userItem);
      
      // Update UI immediately to show user message (optimistic)
      state = state.copyWith(conversationThread: currentThread, isAnalyzing: true);

      // 2. Prepare History for Backend
      final historyForApi = currentThread.map((item) => item.toMap()).toList();

      final result = await _apiService.refineDiagnosis(
        farmerId: farmerId,
        originalDiagnosis: state.diagnosisResult!,
        feedback: feedback,
        contextOverrides: enrichedOverrides,
        interactionHistory: historyForApi,
        language: languageCode,
      );

      final refinementData = result['result'];
      
      // Merge refinement into existing result
      final currentResult = Map<String, dynamic>.from(state.diagnosisResult!);
      
      if (refinementData['is_revised'] == true) {
        currentResult['disease_name'] = refinementData['revised_diagnosis'];
        currentResult['confidence_score'] = refinementData['confidence_score'];
      }
      
      // Always add reasoning and adjustment
      currentResult['refinement_reasoning'] = refinementData['reasoning'];
      currentResult['treatment_adjustment'] = refinementData['treatment_adjustment'];
      
      // Preserve Markers for next refinement
      currentResult['initial_user_input'] = state.diagnosisResult?['initial_user_input'];
      currentResult['initial_ai_response'] = state.diagnosisResult?['initial_ai_response'];


      // 3. Add AI Response to Thread
      final aiItem = ThreadItem(
        role: 'ai',
        content: refinementData['reasoning'] ?? tr('default_ai_response'),
        timestamp: DateTime.now(),
        metadata: refinementData,
      );
      
      final updatedThread = List<ThreadItem>.from(currentThread)..add(aiItem);

      // 4. Save Record
      // Ensure we have seeds for Step 1 & 2 markers
      final String initialRequest = currentResult['initial_user_input'] ?? 
          (state.conversationThread.isNotEmpty ? state.conversationThread.first.content : feedback);
      final String initialDiagnosis = currentResult['initial_ai_response'] ?? 
          (state.conversationThread.length > 1 ? state.conversationThread[1].content : (currentResult['treatment_recommendation'] ?? ''));

      final String recordId = state.activeRecordId ?? (currentResult['analysis_id'] ?? DateTime.now().millisecondsSinceEpoch.toString());

      final historyRecord = DiagnosisRecord(
        id: recordId,
        imagePath: state.imageFile!.path,
        diseaseName: currentResult['disease_name'] ?? tr('unknown_issue'),
        confidence: (currentResult['confidence_score'] ?? 0.0).toDouble(),
        treatmentSummary: currentResult['treatment_recommendation'] ?? '',
        timestamp: DateTime.now(),
        farmerInput: initialRequest, // Root input
        severity: currentResult['severity'] ?? state.diagnosisResult?['severity'],
        languageCode: languageCode,
        cropName: activeField?.cropType ?? currentResult['crop_name'] ??'onion',
        refinementReasoning: currentResult['refinement_reasoning'],
        treatmentAdjustment: currentResult['treatment_adjustment'],
        initialUserInput: initialRequest,
        initialAiResponse: initialDiagnosis,
        thread: updatedThread,
      );
      
      // Hierarchical Save (Refinement)
      if (profileState.selectedFieldId != null && profileState.activeCycleId != null) {
        final userId = authState.value?.id ?? "anonymous";
        await LocalVault().saveDiagnosis(
          historyRecord,
          userId: userId,
          fieldId: profileState.selectedFieldId!,
          cycleId: profileState.activeCycleId!,
        );

        // Auto-Refresh: Invalidate history provider to update dashboard/history list
        _ref.invalidate(diagnosisHistoryProvider);
      }

      state = state.copyWith(
        isAnalyzing: false,
        diagnosisResult: currentResult,
        conversationThread: updatedThread,
      );
    } catch (e) {
      final tr = _ref.read(languageProvider.notifier);
      state = state.copyWith(
        isAnalyzing: false,
        errorMessage: "${tr.translate('refinement_failed')}: ${e.toString()}",
      );
    }
  }

  /// Clear the selected image and results
  void clearImage() {
    _player.stop();
    state = const DiagnosisState();
  }

  void reset() {
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

    final tr = _ref.read(languageProvider.notifier);
    final treatment = state.diagnosisResult!['treatment_recommendation'] ?? tr.translate('no_advice_available');
    final disease = state.diagnosisResult!['disease_name'] ?? tr.translate('unknown_issue');
    final textToSpeak = "${tr.translate('diagnosis_prefix')}: $disease. ${tr.translate('recommendation_prefix')}: $treatment";

    state = state.copyWith(isSynthesizing: true, errorMessage: null);

    try {
      // Get user language for TTS
      final authState = _ref.read(authStateProvider);
      final String languageCode = authState.value?.language ?? 'en-IN';
      
      final audioBytes = await _apiService.synthesizeSpeech(textToSpeak, languageCode);
      debugPrint("TTS: Received ${audioBytes.length} bytes");
      
      if (audioBytes.isEmpty) {
        throw Exception(tr.translate('audio_empty_error'));
      }

      final dataUrl = Uri.dataFromBytes(audioBytes, mimeType: 'audio/mpeg').toString();
      await _player.setAudioSource(AudioSource.uri(Uri.parse(dataUrl)));
      
      _player.play();
      debugPrint("TTS: play() instruction sent");
      state = state.copyWith(isSynthesizing: false, isAudioPlaying: true);
    } catch (e) {
      debugPrint("TTS Error in playAdvice: $e");
      final tr = _ref.read(languageProvider.notifier);
      state = state.copyWith(
        isSynthesizing: false,
        errorMessage: "${tr.translate('audio_play_failed')}: $e",
      );
    }
  }

  /// Delete a specific record
  Future<void> deleteRecord(String recordId) async {
    final authState = _ref.read(authStateProvider);
    final profileState = _ref.read(profileProvider);
    final userId = authState.value?.id;
    final fieldId = profileState.selectedFieldId;
    final cycleId = profileState.activeCycleId;

    if (userId != null && fieldId != null && cycleId != null) {
      final key = PathEnforcer.localCompositeKey(
        userId: userId,
        fieldId: fieldId,
        cycleId: cycleId,
        activityId: recordId,
      );
      await LocalVault().deleteDiagnosisRecord(key);
      _ref.invalidate(diagnosisHistoryProvider);
      
      // If we deleted the active record, clear the state
      if (state.activeRecordId == recordId) {
        reset();
      }
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

/// Provider for Local History (Context-Aware)
final diagnosisHistoryProvider = FutureProvider.autoDispose<List<DiagnosisRecord>>((ref) async {
  final profileState = ref.watch(profileProvider);
  final authState = ref.watch(authStateProvider);
  final userId = authState.value?.id;
  
  if (userId == null || profileState.selectedFieldId == null || profileState.activeCycleId == null) {
    return [];
  }

  return LocalVault().getHistory(
    userId: userId,
    fieldId: profileState.selectedFieldId!,
    cycleId: profileState.activeCycleId!,
  );
});
