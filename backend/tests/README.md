# Backend Tests

This directory contains all test files for the AgriPulse backend API.

## Test Files

### `test_api.py`
Comprehensive API test suite covering:
- Health endpoint
- Root endpoint  
- Crop analysis endpoint (Gemini integration)

**Usage:**
```bash
python tests/test_api.py
```

### `test_real_images.py`
Real-world testing with actual onion disease images from `data/raw/`:
- Tests 6 disease categories
- Validates Gemini's diagnostic accuracy
- Measures confidence scores

**Usage:**
```bash
python tests/test_real_images.py
```

### `test_gemini_only.py`
Simplified Gemini test without Firestore dependency:
- Focuses on AI analysis only
- Useful for debugging Gemini integration

**Usage:**
```bash
python tests/test_gemini_only.py
```

### `check_models.py`
Diagnostic utility to list available Gemini models:
- Shows all models accessible with your API key
- Displays supported generation methods

**Usage:**
```bash
python tests/check_models.py
```

## Running All Tests

```bash
# Run main test suite
python tests/test_api.py

# Run with real disease images
python tests/test_real_images.py

# Quick Gemini check
python tests/test_gemini_only.py
```

## Test Results (Latest)

```
✅ Health Check: PASSED
✅ Root Endpoint: PASSED
✅ Crop Analysis (Gemini): PASSED

Total: 3/3 tests passed
```

## Prerequisites

- Server must be running: `./start_server.sh`
- `.env` file configured with API keys
- Firestore database created
