# AgriPulse Backend Test Suite

Comprehensive test suite for the AgriPulse backend, covering API endpoints, services, and integration workflows.

## Test Structure

```
tests/
├── test_api_endpoints.py    # API endpoint tests (FastAPI routes)
├── test_services.py          # Service layer tests (Gemini, Weather, Speech)
├── test_integration.py       # End-to-end integration tests
├── test_weather.py           # Weather service specific tests
├── test_speech.py            # Speech service specific tests
├── test_api.py               # Legacy API tests
└── README.md                 # This file
```

## Running Tests

### Prerequisites

1. Install test dependencies:
```bash
pip install pytest pytest-asyncio httpx
```

2. Ensure `.env` file is configured with API keys:
```bash
GEMINI_API_KEY=your_key
OPENWEATHER_API_KEY=your_key
GOOGLE_APPLICATION_CREDENTIALS=config/service-account.json
```

### Run All Tests

```bash
# From backend directory
cd backend
python -m pytest tests/ -v
```

### Run Specific Test Files

```bash
# API endpoint tests only
python -m pytest tests/test_api_endpoints.py -v

# Service layer tests only
python -m pytest tests/test_services.py -v

# Integration tests only
python -m pytest tests/test_integration.py -v

# Weather tests
python -m pytest tests/test_weather.py -v

# Speech tests
python -m pytest tests/test_speech.py -v
```

### Run Tests with Coverage

```bash
pip install pytest-cov
python -m pytest tests/ --cov=app --cov-report=html
```

View coverage report: `open htmlcov/index.html`

## Test Categories

### 1. API Endpoint Tests (`test_api_endpoints.py`)

Tests all REST API endpoints:
- ✅ Health checks (`/`, `/health`)
- ✅ Crop analysis (`/api/crop/analyze`)
- ✅ Yield prediction (`/api/crop/predict-yield`)
- ✅ Weather endpoints (`/api/weather/current`, `/api/weather/forecast`)
- ✅ Speech endpoints (`/api/speech/transcribe`, `/api/speech/synthesize`)
- ✅ Feedback submission (`/api/feedback/submit`)

**Key Tests:**
- Success scenarios with valid data
- Validation errors with missing/invalid parameters
- File upload handling
- JSON response structure verification

### 2. Service Layer Tests (`test_services.py`)

Tests individual services in isolation:
- ✅ **GeminiService**: Crop analysis, yield prediction
- ✅ **WeatherService**: Current weather, forecasts, mock fallback
- ✅ **SpeechService**: STT, TTS, language support
- ✅ **Weather Providers**: OpenWeather, Google Maps (placeholder)

**Key Tests:**
- Service initialization
- Async method execution
- Error handling and fallbacks
- Mock data when APIs unavailable

### 3. Integration Tests (`test_integration.py`)

Tests end-to-end workflows:
- ✅ **Full Analysis Workflow**: Weather → Speech → Gemini → TTS
- ✅ **Yield Prediction Workflow**: Forecast → Gemini Pro
- ✅ **Multilingual Support**: Tamil, Hindi, Telugu voice I/O
- ✅ **Error Handling**: Graceful degradation
- ✅ **Performance Benchmarks**: Response time validation

**Key Tests:**
- Multi-service coordination
- Data flow between services
- Language-specific workflows
- Performance under 5s for weather, 3s for TTS

### 4. Legacy Tests

- `test_api.py`: Original API tests (kept for compatibility)
- `test_weather.py`: Standalone weather service tests
- `test_speech.py`: Standalone speech service tests

## Test Fixtures

Common fixtures used across tests:

```python
@pytest.fixture
def gemini_service():
    return GeminiService()

@pytest.fixture
def weather_service():
    return WeatherService()

@pytest.fixture
def speech_service():
    return SpeechService()
```

## Mock Data

Tests use mock data when:
- API keys are not configured
- External services are unavailable
- Testing error scenarios

**Mock Providers:**
- Weather: Returns `{"temperature": 28.5, "condition": "Clear", "is_mock": True}`
- Speech: Returns `"Mock transcription"` or dummy audio bytes

## CI/CD Integration

### GitHub Actions Example

```yaml
name: Backend Tests
on: [push, pull_request]
jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2
      - uses: actions/setup-python@v2
        with:
          python-version: '3.10'
      - run: pip install -r requirements.txt
      - run: pip install pytest pytest-asyncio pytest-cov
      - run: pytest tests/ --cov=app
```

## Test Coverage Goals

| Component | Target Coverage |
|-----------|----------------|
| API Endpoints | 90%+ |
| Services | 85%+ |
| Integration | 75%+ |
| Overall | 80%+ |

## Writing New Tests

### Template for API Tests

```python
def test_new_endpoint(self):
    response = client.post("/api/new-endpoint", data={...})
    assert response.status_code == 200
    assert "expected_key" in response.json()
```

### Template for Service Tests

```python
@pytest.mark.asyncio
async def test_new_service_method(self, service_fixture):
    result = await service_fixture.new_method(params)
    assert result is not None
    assert isinstance(result, dict)
```

## Troubleshooting

### Common Issues

1. **Import Errors**: Ensure `PYTHONPATH` includes backend directory
   ```bash
   export PYTHONPATH=$PYTHONPATH:$(pwd)/backend
   ```

2. **Async Test Failures**: Install `pytest-asyncio`
   ```bash
   pip install pytest-asyncio
   ```

3. **API Key Errors**: Tests should gracefully handle missing keys via mocks

4. **Firestore Errors**: Tests don't require live Firestore (mocked in services)

## Performance Benchmarks

Expected response times:
- Weather API: < 5 seconds
- Speech TTS: < 3 seconds
- Gemini Analysis: < 10 seconds
- Yield Prediction: < 15 seconds

## Next Steps

- [ ] Add database integration tests (Firestore)
- [ ] Add authentication/authorization tests
- [ ] Add load testing (Locust)
- [ ] Add security tests (SQL injection, XSS)
- [ ] Add contract tests (Pact)

---

**Last Updated**: Day 3 (Intelligence Bridge Complete)
**Test Count**: 30+ tests across 6 files
**Coverage**: ~80% (estimated)
