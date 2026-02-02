import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_app/core/theme/color_palette.dart';
import 'package:flutter_app/features/crop_diagnosis/providers/diagnosis_provider.dart';
import 'package:flutter_app/features/yield_prediction/providers/language_provider.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

class DiagnosisFeedbackWidget extends ConsumerStatefulWidget {
  const DiagnosisFeedbackWidget({super.key});

  @override
  ConsumerState<DiagnosisFeedbackWidget> createState() => _DiagnosisFeedbackWidgetState();
}

class _DiagnosisFeedbackWidgetState extends ConsumerState<DiagnosisFeedbackWidget> {
  final TextEditingController _feedbackController = TextEditingController();
  
  // Backend Values (English)
  String _soilCondition = 'Normal';
  String _weatherCondition = 'Sunny';
  bool _isExpanded = false;
  
  // Speech to Text
  late stt.SpeechToText _speech;
  bool _isListening = false;

  @override
  void initState() {
    super.initState();
    _speech = stt.SpeechToText();
  }

  // Map Backend Value -> Localization Key
  final Map<String, String> _soilOptionMap = {
    'Normal': 'soil_normal',
    'Dry/Sandy': 'soil_dry',
    'Wet/Clay': 'soil_wet',
    'Waterlogged': 'soil_log',
  };

  final Map<String, String> _weatherOptionMap = {
    'Sunny': 'weather_sunny',
    'Cloudy': 'weather_cloudy',
    'Heavy Rain': 'weather_rain',
    'Windy': 'weather_windy',
  };

  @override
  void dispose() {
    _feedbackController.dispose();
    super.dispose();
  }

  void _submitRefinement() {
    final tr = ref.read(languageProvider.notifier).translate;
    if (_feedbackController.text.isEmpty && _soilCondition == 'Normal' && _weatherCondition == 'Sunny') {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(tr('provide_feedback_error') ?? 'Please add context to refine.')),
      );
      return;
    }

    final overrides = {
      'soil_condition': _soilCondition,
      'weather_condition': _weatherCondition,
    };

    ref.read(diagnosisProvider.notifier).refineDiagnosis(
      _feedbackController.text,
      overrides,
    );
     // Provider handles loading state.
  }

  void _listen() async {
    if (!_isListening) {
      bool available = await _speech.initialize(
        onStatus: (val) {
          if (val == 'done' || val == 'notListening') {
             if (mounted) setState(() => _isListening = false);
          }
        },
        onError: (val) {
           if (mounted) setState(() => _isListening = false);
        },
      );
      if (available) {
        setState(() => _isListening = true);
        
        final language = ref.read(languageProvider);
        final String localeId = _mapLanguageToLocale(language.name);
        
        _speech.listen(
          onResult: (val) {
            setState(() {
              _feedbackController.text = val.recognizedWords;
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
      default: return 'en_IN';   // Default to Indian English
    }
  }

  @override
  Widget build(BuildContext context) {
    // Access state to see if we have a result (don't show if no result)
    final diagnosisState = ref.watch(diagnosisProvider);
    if (diagnosisState.diagnosisResult == null) return const SizedBox.shrink();

    // Check if rationale exists
    final rationale = diagnosisState.diagnosisResult!['refinement_reasoning'];
    
    ref.watch(languageProvider); // Watch for language changes to trigger rebuild
    final tr = ref.read(languageProvider.notifier).translate; // Get translator
    
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: Colors.white,
      child: Column(
        children: [
          // Header (Always Visible)
          InkWell(
            onTap: () {
              setState(() {
                _isExpanded = !_isExpanded;
              });
            },
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                   const Icon(Icons.psychology_alt, color: ColorPalette.emeraldGreen),
                   const SizedBox(width: 12),
                   Expanded(
                     child: Text(
                       tr('challenge_diagnosis') ?? "Challenge Diagnosis",
                       style: const TextStyle(
                         fontWeight: FontWeight.bold,
                         fontSize: 16,
                       ),
                     ),
                   ),
                   Icon(_isExpanded ? Icons.expand_less : Icons.expand_more),
                ],
              ),
            ),
          ),

          // Refinement Result (If exists)
          if (rationale != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              color: Colors.blue.withOpacity(0.05),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("🧬 ${tr('ai_reasoning') ?? 'AI Reasoning'}:", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
                  const SizedBox(height: 4),
                  Text(rationale, style: const TextStyle(fontStyle: FontStyle.italic)),
                ],
              ),
            ),

          // Input Form (Collapsible)
          if (_isExpanded)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Divider(),
                  Text("${tr('soil_condition') ?? 'Soil Condition'}:", style: const TextStyle(fontWeight: FontWeight.w500)),
                  Wrap(
                    spacing: 8,
                    children: _soilOptionMap.entries.map((entry) {
                      return ChoiceChip(
                        label: Text(tr(entry.value) ?? entry.key), // Translate or fallback
                        selected: _soilCondition == entry.key,
                        onSelected: (val) => setState(() => _soilCondition = entry.key),
                        selectedColor: ColorPalette.emeraldGreen.withOpacity(0.2),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 8),
                  
                  Text("${tr('weather_condition') ?? 'Weather Condition'}:", style: const TextStyle(fontWeight: FontWeight.w500)),
                  Wrap(
                    spacing: 8,
                    children: _weatherOptionMap.entries.map((entry) {
                      return ChoiceChip(
                        label: Text(tr(entry.value) ?? entry.key),
                        selected: _weatherCondition == entry.key,
                        onSelected: (val) => setState(() => _weatherCondition = entry.key),
                        selectedColor: ColorPalette.emeraldGreen.withOpacity(0.2),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 12),

                  TextField(
                    controller: _feedbackController,
                    decoration: InputDecoration(
                      labelText: tr('missed_info_hint') ?? "What did I miss?",
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      suffixIcon: GestureDetector(
                        onTap: _listen,
                        child: Icon(
                          _isListening ? Icons.mic : Icons.mic_none,
                          color: _isListening ? Colors.red : Colors.grey,
                        ),
                      ),
                    ),
                    maxLines: 2,
                  ),
                  const SizedBox(height: 16),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: diagnosisState.isAnalyzing ? null : _submitRefinement,
                      icon: diagnosisState.isAnalyzing 
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                          : const Icon(Icons.refresh),
                      label: Text(diagnosisState.isAnalyzing ? (tr('refining') ?? "Refining...") : (tr('ask_second_opinion') ?? "Ask Second Opinion")),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: ColorPalette.emeraldGreen,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
