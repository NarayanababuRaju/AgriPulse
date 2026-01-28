# AgriPulse - Dependencies & Packages

**Project**: AgriPulse (AI-powered agricultural advisory platform)  
**Framework**: Flutter (Frontend) + FastAPI (Backend)  
**Date**: January 28, 2026

---

## 1. FLUTTER / DART DEPENDENCIES

### 1.1 Core Flutter Packages

| Package | Version | Purpose | Category |
|---------|---------|---------|----------|
| `flutter` | 3.19.0+ | Core Flutter framework | Core |
| `dart_sdk` | 3.1.0+ | Dart language runtime | Core |

### 1.2 State Management & Architecture

| Package | Version | Purpose | Notes |
|---------|---------|---------|-------|
| `riverpod` | ^2.4.0 | Reactive state management | Primary state container |
| `riverpod_generator` | ^2.3.0 | Code generation for Riverpod | Auto-generates providers |
| `freezed_annotation` | ^2.4.0 | Immutable model generation | Immutable value objects |
| `freezed` | ^2.4.0 | Code generation for freezed | Auto-generates classes |
| `json_serializable` | ^6.7.0 | JSON serialization | Model ↔ JSON conversion |
| `json_annotation` | ^4.8.0 | JSON annotations | Marks serializable classes |
| `build_runner` | ^2.4.0 | Code generation runner | Runs build tasks |

### 1.3 Network & API Integration

| Package | Version | Purpose | Usage |
|---------|---------|---------|-------|
| `dio` | ^5.3.0 | HTTP client library | Backend API calls |
| `http` | ^1.1.0 | Lightweight HTTP client | Fallback HTTP requests |
| `connectivity_plus` | ^5.0.0 | Network connectivity detection | Check online/offline status |
| `google_generative_ai` | ^0.4.0 | Gemini 3 API SDK | Direct Gemini API access |
| `google_maps_flutter` | ^2.5.0 | Google Maps integration | Location & map display |
| `geolocator` | ^9.0.0 | GPS location services | Get farmer's GPS coordinates |

### 1.4 Storage & Database

| Package | Version | Purpose | Usage |
|---------|---------|---------|-------|
| `firebase_core` | ^2.24.0 | Firebase initialization | Firebase services base |
| `firebase_auth` | ^4.13.0 | Firebase authentication | Phone OTP login |
| `cloud_firestore` | ^4.13.0 | Firestore database | Primary cloud database |
| `hive` | ^2.2.0 | Local NoSQL storage | Offline cache for records |
| `hive_flutter` | ^1.1.0 | Hive Flutter integration | Hive UI adaptation |
| `sqflite` | ^2.3.0 | SQLite database | Fallback local storage |
| `path_provider` | ^2.1.0 | File system paths | Access app directories |
| `shared_preferences` | ^2.2.0 | Key-value storage | Simple settings cache |

### 1.5 Audio & Voice

| Package | Version | Purpose | Usage |
|---------|---------|---------|-------|
| `record` | ^5.0.0 | Audio recording | Record farmer's voice input |
| `audio_session` | ^0.1.0 | Audio session management | Manage app audio |
| `just_audio` | ^0.9.0 | Audio playback | Play Gemini text-to-speech responses |
| `flutter_sound` | ^9.14.0 | Advanced audio features | Optional: enhanced audio features |

### 1.6 Camera & Image Processing

| Package | Version | Purpose | Usage |
|---------|---------|---------|-------|
| `camera` | ^0.10.0 | Camera access | Capture crop photos |
| `image_picker` | ^1.0.0 | Photo/gallery picker | Select existing photos |
| `image` | ^4.0.0 | Image manipulation | Crop/resize images |
| `image_compression_flutter` | ^1.1.0 | Image compression | Reduce upload size |

### 1.7 UI & UX

| Package | Version | Purpose | Usage |
|---------|---------|---------|-------|
| `flutter_svg` | ^2.0.0 | SVG support | Icons & graphics |
| `lottie` | ^2.7.0 | Animation library | Animated UI elements |
| `shimmer` | ^3.0.0 | Loading shimmer effect | Loading placeholders |
| `intl` | ^0.19.0 | Localization & i18n | Multi-language support |
| `easy_localization` | ^3.0.0 | Localization framework | Tamil, Telugu, Kannada, etc. |
| `get_it` | ^7.5.0 | Service locator | Dependency injection |
| `device_info_plus` | ^9.0.0 | Device info | Get device details |

### 1.8 Testing & Development

| Package | Version | Purpose | Usage |
|---------|---------|---------|-------|
| `flutter_test` | Flutter SDK | Unit testing framework | Write unit tests |
| `mockito` | ^5.4.0 | Mocking library | Mock API responses |
| `integration_test` | Flutter SDK | Integration testing | E2E tests |

### 1.9 Utility Packages

| Package | Version | Purpose | Usage |
|---------|---------|---------|-------|
| `logger` | ^2.0.0 | Logging framework | Debug logging |
| `envied` | ^0.5.0 | Environment variables | Store API keys securely |
| `uuid` | ^4.0.0 | UUID generation | Generate unique IDs |
| `intl_phone_number_input` | ^0.7.0 | Phone number input | Validate phone numbers |
| `url_launcher` | ^6.1.0 | Open URLs | Launch external links |
| `permission_handler` | ^11.4.0 | Request permissions | Camera, location, microphone |

### 1.10 pubspec.yaml Summary

```yaml
name: agripulse
description: AI-powered agricultural advisory platform
version: 1.0.0+1

environment:
  sdk: ">=3.1.0 <4.0.0"
  flutter: ">=3.19.0"

dependencies:
  flutter:
    sdk: flutter
  
  # State Management
  riverpod: ^2.4.0
  riverpod_generator: ^2.3.0
  freezed_annotation: ^2.4.0
  json_serializable: ^6.7.0
  json_annotation: ^4.8.0
  
  # Network
  dio: ^5.3.0
  http: ^1.1.0
  connectivity_plus: ^5.0.0
  google_generative_ai: ^0.4.0
  
  # Firebase & Storage
  firebase_core: ^2.24.0
  firebase_auth: ^4.13.0
  cloud_firestore: ^4.13.0
  hive: ^2.2.0
  hive_flutter: ^1.1.0
  sqflite: ^2.3.0
  shared_preferences: ^2.2.0
  
  # Audio & Voice
  record: ^5.0.0
  just_audio: ^0.9.0
  
  # Camera & Images
  camera: ^0.10.0
  image_picker: ^1.0.0
  image: ^4.0.0
  
  # UI & UX
  flutter_svg: ^2.0.0
  lottie: ^2.7.0
  shimmer: ^3.0.0
  intl: ^0.19.0
  easy_localization: ^3.0.0
  get_it: ^7.5.0
  
  # Google Maps
  google_maps_flutter: ^2.5.0
  geolocator: ^9.0.0
  
  # Utilities
  logger: ^2.0.0
  envied: ^0.5.0
  uuid: ^4.0.0
  url_launcher: ^6.1.0
  permission_handler: ^11.4.0

dev_dependencies:
  flutter_test:
    sdk: flutter
  build_runner: ^2.4.0
  freezed: ^2.4.0
  flutter_lints: ^3.0.0
  mockito: ^5.4.0
```

---

## 2. FASTAPI / PYTHON DEPENDENCIES

### 2.1 Core Framework

| Package | Version | Purpose | Notes |
|---------|---------|---------|-------|
| `fastapi` | ^0.104.0 | Web framework | Async API server |
| `uvicorn` | ^0.24.0 | ASGI server | Production server |
| `python` | ^3.10 | Python runtime | Required version |
| `pydantic` | ^2.5.0 | Data validation | Request/response validation |
| `pydantic-settings` | ^2.1.0 | Environment config | Load .env variables |

### 2.2 Google Cloud & AI Services

| Package | Version | Purpose | Usage |
|---------|---------|---------|-------|
| `google-generativeai` | >=0.8.0 | Gemini 3 API SDK | Crop analysis & predictions (using gemini-3-flash-preview & gemini-3-pro-preview) |
| `google-cloud-speech` | 2.23.0 | Speech-to-Text API | Transcribe farmer voice |
| `google-cloud-texttospeech` | 2.15.1 | Text-to-Speech API | Generate voice responses |
| `google-cloud-firestore` | 2.13.1 | Firestore SDK | Database operations |
| `google-cloud-storage` | 2.13.0 | Cloud Storage SDK | Store crop images |
| `google-auth` | Latest | Google authentication | Service account auth |
| `firebase-admin` | 6.2.0 | Firebase Admin SDK | Firestore & Auth management |

### 2.3 HTTP & API Clients

| Package | Version | Purpose | Usage |
|---------|---------|---------|-------|
| `httpx` | 0.25.2 | HTTP client | Make external API calls |
| `python-multipart` | 0.0.6 | Multipart form data | Handle file uploads |

### 2.4 Utilities & Development

| Package | Version | Purpose | Usage |
|---------|---------|---------|-------|
| `python-dotenv` | 1.0.0 | Load .env files | Development environment |
| `loguru` | 0.7.2 | Logging framework | Structured logging |
| `aiocache` | 0.12.2 | Async caching | Cache API responses |
| `pytest` | 7.4.3 | Testing framework | Write unit tests |

### 2.5 requirements.txt (Actual)

```txt
# Core Framework
fastapi==0.104.1
uvicorn==0.24.0
pydantic==2.5.2
pydantic-settings==2.1.0

# Google Cloud & AI (Updated for Gemini 3.0)
google-generativeai>=0.8.0
google-cloud-speech==2.23.0
google-cloud-texttospeech==2.15.1
google-cloud-firestore==2.13.1
google-cloud-storage==2.13.0
firebase-admin==6.2.0

# HTTP Clients
httpx==0.25.2
python-multipart==0.0.6

# Utilities
python-dotenv==1.0.0
loguru==0.7.2
aiocache==0.12.2

# Testing
pytest==7.4.3
```

**Note**: We upgraded `google-generativeai` to 0.8.6 during development to support Gemini 3.0 Flash and Pro Preview models.

---

## 3. EXTERNAL SERVICES & APIs

### 3.1 Google Cloud Platform

| Service | Purpose | Pricing |
|---------|---------|---------|
| **Gemini 3 API** | Crop analysis & yield prediction | $0.075-0.30/M tokens |
| **Cloud Speech-to-Text** | Voice transcription (6 languages) | $0.024-0.036/minute |
| **Cloud Text-to-Speech** | Voice synthesis (local languages) | $0.000004/character |
| **Cloud Storage** | Store crop photos temporarily | $0.020/GB (free tier: 1GB) |
| **Cloud Run** | Backend deployment (serverless) | $0.00001667/vCPU-second |
| **Firestore** | Primary database | Free: 1GB storage + 50k reads |
| **Cloud Tasks** | Queue management | $0.10/million operations |
| **Maps Platform** | Weather data & location services | $7/month (free: $200 credit) |

### 3.2 Third-Party APIs

| Service | Purpose | Endpoint |
|---------|---------|----------|
| **AGMARKNET** | Agricultural market prices | https://agmarknet.gov.in |
| **OpenWeatherMap** | Weather fallback (optional) | https://openweathermap.org |
| **Government Schemes DB** | Policy information (custom) | Manual ingestion |

---

## 4. DEVELOPMENT TOOLS & SETUP

### 4.1 Local Development Environment

```bash
# Flutter
flutter --version          # 3.19.0+
flutter pub get            # Install dependencies

# Python
python --version           # 3.10+
pip install --upgrade pip
pip install -r requirements.txt

# Environment Configuration
.env.example              # Template for API keys
.firebase/               # Firebase config files
```

### 4.2 Required API Keys / Credentials

| Service | Variable | Where to Get |
|---------|----------|--------------|
| **Gemini 3 API** | `GOOGLE_API_KEY` | [Google AI Studio](https://aistudio.google.com) |
| **Firebase Project** | `FIREBASE_PROJECT_ID` | [Firebase Console](https://console.firebase.google.com) |
| **Google Cloud** | `GOOGLE_APPLICATION_CREDENTIALS` | GCP service account JSON |
| **OpenWeatherMap** (optional) | `OPENWEATHER_API_KEY` | [OpenWeather](https://openweathermap.org) |

### 4.3 Directory Structure for Dependencies

```
AgriPulse/
├── flutter_app/
│   ├── pubspec.yaml          # Flutter dependencies
│   ├── pubspec.lock          # Lock file (auto-generated)
│   └── lib/
├── backend/
│   ├── requirements.txt       # Python dependencies
│   ├── requirements-dev.txt   # Dev dependencies
│   ├── app/
│   │   ├── main.py
│   │   └── ...
│   └── .env.example           # Template for secrets
├── .env                       # Local environment (not in git)
├── .env.example               # Template (in git)
└── DEPENDENCIES.md            # This file
```

---

## 5. DEPENDENCY INSTALLATION COMMANDS

### 5.1 Flutter Setup

```bash
cd flutter_app
flutter pub get
flutter pub upgrade          # Update to latest compatible versions
```

### 5.2 FastAPI Backend Setup

```bash
cd backend
python -m venv venv          # Create virtual environment
source venv/bin/activate     # Activate venv (macOS/Linux)
pip install -r requirements.txt
```

### 5.3 Development Dependencies (Optional)

```bash
# For Flutter development tools
flutter pub get dev
flutter packages get

# For Python testing
pip install -r requirements-dev.txt
```

---

## 6. VERSION COMPATIBILITY MATRIX

### Minimum Requirements

| Component | Minimum Version | Recommended | EOL |
|-----------|-----------------|-------------|-----|
| **Flutter** | 3.19.0 | 3.24.0+ | Dec 2026 |
| **Dart** | 3.1.0 | 3.3.0+ | Dec 2025 |
| **Python** | 3.10 | 3.11.0+ | Oct 2026 |
| **Android SDK** | 21 | 34+ | - |
| **iOS** | 11.0 | 14.0+ | - |

### Breaking Changes (If Upgrading)

- **Riverpod 2.x**: Providers are now sealed (non-final methods removed)
- **Pydantic 2.x**: Schema changes; use `model_validate()` instead of `parse_obj()`
- **Firebase SDK 4.x**: Requires Java 11+ for Android

---

## 7. SECURITY & BEST PRACTICES

### 7.1 API Key Management

```bash
# Store in .env (NOT in git)
GOOGLE_API_KEY=your_key_here
FIREBASE_CONFIG={"config": "here"}

# Load safely
from pydantic_settings import BaseSettings

class Settings(BaseSettings):
    google_api_key: str
    firebase_config: dict
    
    class Config:
        env_file = ".env"
```

### 7.2 Dependency Auditing

```bash
# Check for security vulnerabilities
pip-audit                    # Python packages
flutter pub outdated         # Flutter packages
```

### 7.3 Lock Files

- **pubspec.lock**: Auto-generated; commit to git
- **requirements.txt**: Pinned versions; commit to git
- **.env**: DO NOT commit; add to .gitignore

---

## 8. OPTIONAL / FUTURE DEPENDENCIES

### On-Device ML (Phase 2)

```yaml
# Flutter
tflite_flutter: ^0.10.0          # TensorFlow Lite for Dart

# Python
tensorflow: ^2.14.0              # TensorFlow for server-side models
torch: ^2.1.0                    # PyTorch (optional)
```

### Advanced Features (Phase 2+)

```python
# Automated machine learning
auto-sklearn==0.15.0             # AutoML for yield predictions
xgboost==2.0.0                   # Gradient boosting

# Advanced NLP
transformers==4.34.0             # HuggingFace models
spacy==3.7.0                     # NLP pipeline
```

---

## 9. DEPENDENCY GRAPH

### Critical Path (MVP)

```
FastAPI (Core)
├─ Pydantic (validation)
├─ Uvicorn (server)
├─ google-generativeai (Gemini)
├─ google-cloud-firestore (database)
├─ google-cloud-speech (voice input)
└─ google-cloud-texttospeech (voice output)

Flutter (Frontend)
├─ Riverpod (state management)
├─ Dio (network)
├─ Firebase (auth)
├─ record (audio input)
├─ just_audio (audio output)
└─ camera (image capture)
```

---

## 10. COST ESTIMATION

### Monthly Cost (Estimated - MVP Phase)

| Service | Monthly Quota | Estimated Cost |
|---------|---------------|-----------------|
| Gemini 3 API | 10M tokens | $0.75 |
| Speech-to-Text | 50k minutes | $1,200 ⚠️ (EXPENSIVE) |
| Text-to-Speech | 100M characters | $0.40 |
| Cloud Storage | 10GB | $0.20 |
| Cloud Run | 1M invocations | $0.40 |
| Firestore | 1GB + reads | FREE (under quota) |
| **TOTAL** | - | ~$2,417 (dominated by Speech) |

### Cost Optimization

- **Speech API**: Cache voice responses, use batch processing
- **Gemini 3**: Context caching for repeated queries
- **Storage**: Auto-delete temporary images after 24h
- **Cloud Run**: Use free tier (~2M requests/month)

---

## 11. MAINTENANCE & UPDATES

### Dependency Update Schedule

```
Monthly: pip-audit, flutter pub outdated
Quarterly: Major version updates (test thoroughly)
On-demand: Security patches (apply immediately)
```

### Deprecation Warnings

Monitor for:
- Google Cloud API deprecations (notify quarterly)
- Flutter plugin incompatibilities
- Python package end-of-life dates

---

**Date Created**: January 28, 2026
**Last Updated**: January 28, 2026