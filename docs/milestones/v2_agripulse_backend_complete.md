# Milestone V2: Backend Complete

**Status**: 🚧 Partial (Backend Complete, Frontend In-Progress)
**Date**: Jan 29, 2026

## 1. Overview
This milestone marks the completion of the **AgriPulse Backend Core**, a high-performance FastAPI engine capable of multimodal reasoning for onion farming (Gemini 3) and localization (Speech/Weather).

## 2. "As-Built" Architecture (Backend)

### 2.1 Core Services (`backend/app/services/`)
*   **`GeminiService`**:
    *   **Models**: `gemini-3.0-flash-preview` (Diagnosis), `gemini-3.0-pro-preview` (Yield Reasoning).
    *   **Logic**: Multimodal prompts injecting `weather_context` and `farmer_history`.
*   **`SpeechService`**:
    *   **STT**: Transcribes local Indian dialects (Hindi, Tamil, etc.) to English using context-preserving Google Cloud API.
    *   **TTS**: Synthesizes responses back to local language audio, orchestrated via byte-stream buffers.
*   **`WeatherService` (Climate-Intelligence Engine)**:
    *   **Logic**: Beyond fetching forecasts, it analyzes local climate data to inject "Environmental Triggers" (e.g., moisture levels) into Gemini reasoning for preventive onion disease alerts.
    *   **Providers**: `OpenWeatherMap` (Forecast) + `Google Maps` (Validation).
    *   **Output**: Normalized structural data for Gemini context.
*   **`FirestoreService`**:
    *   **Collections**: `users` (Profiles), `analyses` (Onion Diseases), `predictions` (Yield).

### 2.2 API Layer (`backend/app/api/`)
*   `POST /api/crop/analyze`: Orchestrator endpoint.
    *   **Input**: Image + Voice Text + Farmer ID + Weather Context.
    *   **Flow**: Parse Weather -> Call Gemini 3 Flash -> Save to Firestore -> Return JSON.
*   `POST /api/crop/predict-yield`: High-reasoning endpoint.
    *   **Input**: Soil + Crop Data + 7-Day Forecast.
    *   **Flow**: Call Gemini 3 Pro (Reasoning Mode) -> Save Prediction.

## 3. "As-Built" Architecture (Frontend - Mobile)

*   **Framework**: Flutter (Dart)
*   **State**: Riverpod 2.0
*   **Current Modules**:
    *   **Auth**: Phone Authentication (Firebase).
    *   **Dashboard**: "At-a-glance" weather and quick actions.
    *   **Crop Doctor**: MVP UI for Image Capture (Backend integration pending Day 5).

## 4. Deviations from V1 Plan

| Feature | V1 Plan | V2 Actual | Reason |
| :--- | :--- | :--- | :--- |
| **Market Data** | Live AGMARKNET API | **Postponed** | prioritized Diagnostic Accuracy & Voice |
| **Offline Sync** | Custom Queue Endpoint | **Pending Phase 3** | Focus on Online Real-time interaction first |
| **Voice** | `voice_service.py` | `speech_service.py` | Renamed for clarity; added TTS |
| **Weather** | `data_engine.py` | `weather_service.py` | Decoupled from generic data engine |

## 5. Next Steps (Day 4 & 5)
1.  **Frontend Hardening (v2.5)**: Fix linter issues and UI polish (Shimmer, Error Handlers).
2.  **API Integration**: Connect Flutter `AgriPulseService` to Backend `ApiClient` (Dio).
3.  **State Logic Verification**: Unit testing `DiagnosisProvider` with Mockito to ensure state-machine stability.
4.  **End-to-End Test**: Verify "Speak -> Upload -> Diagnose" flow on device.
