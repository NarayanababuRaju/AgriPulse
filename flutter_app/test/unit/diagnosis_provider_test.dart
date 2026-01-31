import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:just_audio/just_audio.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:flutter_app/features/crop_diagnosis/providers/diagnosis_provider.dart';
import 'package:flutter_app/core/api/agri_pulse_service.dart';

@GenerateNiceMocks([MockSpec<AudioPlayer>(), MockSpec<AgriPulseService>()])
import 'diagnosis_provider_test.mocks.dart';

/// Unit Tests for Crop Diagnosis Provider
void main() {
  group('DiagnosisController Tests', () {
    late MockAudioPlayer mockAudioPlayer;
    late MockAgriPulseService mockApiService;
    late ProviderContainer container;

    setUp(() {
      mockAudioPlayer = MockAudioPlayer();
      mockApiService = MockAgriPulseService();
      
      // Stub the playerStateStream which is called in constructor
      when(mockAudioPlayer.playerStateStream).thenAnswer((_) => const Stream.empty());
      
      container = ProviderContainer(
        overrides: [
          diagnosisProvider.overrideWith((ref) {
            return DiagnosisController(mockApiService, ref, player: mockAudioPlayer);
          }),
        ],
      );
    });

    tearDown(() {
      container.dispose();
    });

    test('initial state should have no image', () {
      final state = container.read(diagnosisProvider);
      
      expect(state.imageFile, isNull);
      expect(state.isAnalyzing, isFalse);
      expect(state.errorMessage, isNull);
    });

    test('clearImage should reset state', () {
      final controller = container.read(diagnosisProvider.notifier);
      
      controller.clearImage();
      
      final state = container.read(diagnosisProvider);
      expect(state.imageFile, isNull);
      expect(state.isAnalyzing, isFalse);
    });

    test('analyzeImage with no image should do nothing', () async {
      final controller = container.read(diagnosisProvider.notifier);
      
      await controller.analyzeImage();
      
      final state = container.read(diagnosisProvider);
      expect(state.isAnalyzing, isFalse);
    });

    test('state should be copyable', () {
      const state1 = DiagnosisState(isAnalyzing: false);
      final state2 = state1.copyWith(isAnalyzing: true);
      
      expect(state1.isAnalyzing, isFalse);
      expect(state2.isAnalyzing, isTrue);
    });
  });
}
