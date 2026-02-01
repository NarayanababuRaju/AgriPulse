AgriPulse is a voice-enabled, multimodal AI assistant for small-scale farmers in India, built for **Climate-Resilient Agriculture**. This plan outlines the direct technical path to the Gemini 3.0-powered Hackathon MVP.

## [Component 1] Cloud Infrastructure (GCP & Firebase)
- **[NEW] Firebase Setup**: Configure Phone Auth (OTP) and Firestore.
- **[NEW] GCS Buckets**: Create buckets for crop photos with a 24-hour TTL (Time-To-Live) for cleanup.
- **[NEW] Cloud Tasks**: Initialize a queue for processing offline-synced requests.

## [Component 2] Backend Services (FastAPI/Python)
- **[NEW] `services/voice_service.py`**: Integration with Google Cloud STT/TTS (6 regional languages) using secure Service Account orchestration.
- **[NEW] `services/data_engine.py`**: Integration with Google Maps Weather API and AGMARKNET (India Market) for context-aware reasoning.
- **[NEW] `services/gemini_service.py`**: The central "Brain" (Gemini 3.0). It accepts multimodal payloads (Image + Voice + Context) and returns structured JSON advice for onion diagnostics.
- **[NEW] `api/sync_endpoint.py`**: Handles incoming batches from the Flutter client's offline queue.

## [Component 3] Mobile Client (Flutter)
- **[NEW] `lib/services/sync_manager.dart`**: Robust "Queue & Sync" logic using local SQLite and background tasks.
- **[NEW] `lib/screens/voice_consultant.dart`**: Real-time wave animation for audio recording + camera capture.
- **[NEW] `lib/widgets/feedback_panel.dart`**: Ability for farmers to rate/correct Gemini's advice.

## [Component 4] Gemini 3 Multimodal Prompting
- **System Instructions**: Pre-loaded with regional agricultural terminology (Onion, Rabi, Kharif) and India-specific onion disease data (Purple Blotch, Basal Rot, Downy Mildew).
- **Output Schema**: Forced JSON output for UI mapping:
  ```json
  {
    "disease": "Purple Blotch",
    "severity": "Medium",
    "confidence": 0.92,
    "treatment": {
      "organic": "Neem Oil Spray",
      "chemical": "Mancozeb 75% WP"
    },
    "yield_impact": "-15%",
    "audio_response_text": "விவசாயி அவர்களே, உங்கள் வெங்காயப் பயிரில் ஊதா நிறப் புள்ளி நோய்..."
  }
  ```

## Verification Plan
1. **Scenario 1: Offline Recording**: Simulate poor network, record "எனது வெங்காயப் பயிர் மஞ்சளாக உள்ளது" (My onion crop is yellow), take photo, verify it syncs and responds in Tamil when network returns.
2. **Scenario 2: Market Correlation**: Verify that Gemini identifies excess rainfall in the 7-day weather forecast and correctly links it to a projected price spike for moisture-sensitive crops like Onions (due to rot risk).
