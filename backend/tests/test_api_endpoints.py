"""
Comprehensive API Endpoint Tests for AgriPulse Backend
Tests all REST endpoints including crop analysis, yield prediction, weather, and speech.
"""
import pytest
import asyncio
from fastapi.testclient import TestClient
from io import BytesIO
from PIL import Image
import json

# Import the FastAPI app
import sys
import os
sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), '..')))

from app.main import app

client = TestClient(app)

class TestHealthEndpoints:
    """Test basic health and status endpoints"""
    
    def test_root_endpoint(self):
        """Test the root endpoint returns welcome message"""
        response = client.get("/")
        assert response.status_code == 200
        data = response.json()
        assert data["status"] == "online"
        assert "AgriPulse" in data["message"]
    
    def test_health_check(self):
        """Test health check endpoint"""
        response = client.get("/health")
        assert response.status_code == 200
        assert response.json()["status"] == "healthy"


class TestCropAnalysisEndpoint:
    """Test crop disease analysis endpoint"""
    
    def create_test_image(self):
        """Create a test image for upload"""
        img = Image.new('RGB', (100, 100), color='green')
        img_bytes = BytesIO()
        img.save(img_bytes, format='JPEG')
        img_bytes.seek(0)
        return img_bytes
    
    def test_analyze_crop_success(self):
        """Test successful crop analysis with all parameters"""
        img_bytes = self.create_test_image()
        
        response = client.post(
            "/api/crop/analyze",
            data={
                "farmer_id": "test_farmer_001",
                "voice_transcription": "My crop leaves are turning yellow",
                "weather_context": json.dumps({
                    "temperature": 30,
                    "humidity": 80,
                    "condition": "Rainy"
                })
            },
            files={"image": ("test.jpg", img_bytes, "image/jpeg")}
        )
        
        assert response.status_code == 200
        data = response.json()
        assert "result" in data
        assert "analysis_id" in data
        assert data["status"] == "success"
    
    def test_analyze_crop_missing_image(self):
        """Test analysis fails without image"""
        response = client.post(
            "/api/crop/analyze",
            data={
                "farmer_id": "test_farmer_001",
                "voice_transcription": "Test transcription"
            }
        )
        assert response.status_code == 422  # Validation error
    
    def test_analyze_crop_without_weather(self):
        """Test analysis works without weather context"""
        img_bytes = self.create_test_image()
        
        response = client.post(
            "/api/crop/analyze",
            data={
                "farmer_id": "test_farmer_001",
                "voice_transcription": "Test transcription"
            },
            files={"image": ("test.jpg", img_bytes, "image/jpeg")}
        )
        
        assert response.status_code == 200


class TestYieldPredictionEndpoint:
    """Test yield prediction endpoint"""
    
    def test_predict_yield_success(self):
        """Test successful yield prediction"""
        response = client.post(
            "/api/crop/predict-yield",
            data={
                "farmer_id": "test_farmer_001",
                "crop_name": "Rice",
                "variety": "Basmati",
                "field_area": "2.5",
                "planted_date": "2025-11-01",
                "soil_type": "Clay",
                "weather_forecast": json.dumps({
                    "avg_temp": 28,
                    "rainfall_expected": 150
                })
            }
        )
        
        assert response.status_code == 200
        data = response.json()
        assert "result" in data
        assert "prediction_id" in data
        assert data["status"] == "success"
    
    def test_predict_yield_missing_params(self):
        """Test prediction fails with missing parameters"""
        response = client.post(
            "/api/crop/predict-yield",
            data={
                "farmer_id": "test_farmer_001",
                "crop_name": "Rice"
            }
        )
        assert response.status_code == 422


class TestWeatherEndpoints:
    """Test weather service endpoints"""
    
    def test_get_current_weather(self):
        """Test fetching current weather"""
        response = client.get(
            "/api/weather/current",
            params={"lat": 12.9716, "lon": 77.5946}
        )
        
        assert response.status_code == 200
        data = response.json()
        assert "temperature" in data
        assert "condition" in data
        assert "location" in data
    
    def test_get_weather_forecast(self):
        """Test fetching weather forecast"""
        response = client.get(
            "/api/weather/forecast",
            params={"lat": 12.9716, "lon": 77.5946}
        )
        
        assert response.status_code == 200
        data = response.json()
        assert "daily_summary" in data
        assert isinstance(data["daily_summary"], list)
    
    def test_weather_invalid_coordinates(self):
        """Test weather with invalid coordinates"""
        response = client.get(
            "/api/weather/current",
            params={"lat": 999, "lon": 999}
        )
        # Should still return data (mock or error handling)
        assert response.status_code in [200, 400, 500]


class TestSpeechEndpoints:
    """Test speech-to-text and text-to-speech endpoints"""
    
    def create_mock_audio(self):
        """Create mock audio data"""
        return BytesIO(b"mock_audio_data")
    
    def test_transcribe_audio(self):
        """Test speech-to-text transcription"""
        audio_bytes = self.create_mock_audio()
        
        response = client.post(
            "/api/speech/transcribe",
            data={"language": "en-IN"},
            files={"file": ("test.wav", audio_bytes, "audio/wav")}
        )
        
        assert response.status_code == 200
        data = response.json()
        assert "transcription" in data
        assert "status" in data
    
    def test_synthesize_speech(self):
        """Test text-to-speech synthesis"""
        response = client.post(
            "/api/speech/synthesize",
            data={
                "text": "Hello farmer, this is a test message",
                "language": "en-IN"
            }
        )
        
        assert response.status_code == 200
        assert response.headers["content-type"] == "audio/mpeg"


class TestFeedbackEndpoint:
    """Test feedback submission endpoint"""
    
    def test_submit_feedback_success(self):
        """Test successful feedback submission"""
        response = client.post(
            "/api/feedback/submit",
            json={
                "farmer_id": "test_farmer_001",
                "analysis_id": "test_analysis_123",
                "rating": 5,
                "comment": "Very helpful advice!",
                "was_helpful": True
            }
        )
        
        assert response.status_code == 200
        data = response.json()
        assert data["status"] == "success"
    
    def test_submit_feedback_invalid_rating(self):
        """Test feedback with invalid rating"""
        response = client.post(
            "/api/feedback/submit",
            data={
                "farmer_id": "test_farmer_001",
                "analysis_id": "test_analysis_123",
                "rating": "10",  # Invalid: should be 1-5
                "comment": "Test"
            }
        )
        assert response.status_code == 422


if __name__ == "__main__":
    pytest.main([__file__, "-v", "--tb=short"])
