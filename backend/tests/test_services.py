"""
Service Layer Tests for AgriPulse Backend
Tests Gemini, Weather, and Speech services in isolation.
"""
import pytest
import asyncio
import os
from dotenv import load_dotenv

# Load environment variables
load_dotenv(os.path.join(os.path.dirname(__file__), "../.env"))

import sys
sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), '..')))

from app.services.gemini_service import GeminiService
from app.services.weather_service import WeatherService
from app.services.speech_service import SpeechService


class TestGeminiService:
    """Test Gemini AI service functionality"""
    
    @pytest.fixture
    def gemini_service(self):
        return GeminiService()
    
    @pytest.mark.asyncio
    async def test_analyze_crop_disease(self, gemini_service):
        """Test crop disease analysis with Gemini"""
        # Create a simple test image (1x1 red pixel)
        test_image = b'\xff\xd8\xff\xe0\x00\x10JFIF'  # JPEG header
        
        result = await gemini_service.analyze_crop_disease(
            image_data=test_image,
            voice_transcription="My crop leaves are yellow",
            weather_context={"temperature": 30, "humidity": 80}
        )
        
        assert result is not None
        assert isinstance(result, dict)
    
    @pytest.mark.asyncio
    async def test_predict_yield(self, gemini_service):
        """Test yield prediction with Gemini Pro"""
        result = await gemini_service.predict_yield(
            crop_name="Rice",
            variety="Basmati",
            field_area=2.5,
            planted_date="2025-11-01",
            soil_type="Clay",
            weather_forecast={"avg_temp": 28, "rainfall": 150}
        )
        
        assert result is not None
        assert isinstance(result, dict)


class TestWeatherService:
    """Test Weather service functionality"""
    
    @pytest.fixture
    def weather_service(self):
        return WeatherService()
    
    @pytest.mark.asyncio
    async def test_get_current_weather(self, weather_service):
        """Test fetching current weather"""
        result = await weather_service.get_current_weather(12.9716, 77.5946)
        
        assert result is not None
        assert "temperature" in result
        assert "condition" in result
        assert "humidity" in result
    
    @pytest.mark.asyncio
    async def test_get_forecast(self, weather_service):
        """Test fetching weather forecast"""
        result = await weather_service.get_forecast(12.9716, 77.5946)
        
        assert result is not None
        assert "daily_summary" in result
        assert isinstance(result["daily_summary"], list)
    
    @pytest.mark.asyncio
    async def test_weather_fallback_to_mock(self, weather_service):
        """Test that service falls back to mock data on error"""
        # Use invalid coordinates to trigger fallback
        result = await weather_service.get_current_weather(999, 999)
        
        # Should still return data (mock)
        assert result is not None
        assert "temperature" in result


class TestSpeechService:
    """Test Speech service functionality"""
    
    @pytest.fixture
    def speech_service(self):
        return SpeechService()
    
    @pytest.mark.asyncio
    async def test_transcribe_audio(self, speech_service):
        """Test speech-to-text transcription"""
        mock_audio = b"mock_audio_data"
        
        result = await speech_service.transcribe_audio(mock_audio, "en-IN")
        
        assert result is not None
        assert isinstance(result, str)
    
    @pytest.mark.asyncio
    async def test_synthesize_speech(self, speech_service):
        """Test text-to-speech synthesis"""
        text = "Hello farmer, this is a test"
        
        result = await speech_service.synthesize_speech(text, "en-IN")
        
        assert result is not None
        assert isinstance(result, bytes)
        assert len(result) > 0
    
    @pytest.mark.asyncio
    async def test_supported_languages(self, speech_service):
        """Test that all supported languages are available"""
        supported = ["ta-IN", "te-IN", "kn-IN", "ml-IN", "hi-IN", "en-IN"]
        
        for lang in supported:
            assert lang in speech_service.SUPPORTED_LANGUAGES.values()


class TestWeatherProviders:
    """Test Weather Provider Strategy Pattern"""
    
    @pytest.mark.asyncio
    async def test_openweather_provider(self):
        """Test OpenWeather provider directly"""
        from app.services.weather_providers.openweather import OpenWeatherProvider
        
        api_key = os.getenv("OPENWEATHER_API_KEY")
        if not api_key:
            pytest.skip("No OpenWeather API key configured")
        
        provider = OpenWeatherProvider(api_key)
        result = await provider.get_current_weather(12.9716, 77.5946)
        
        assert result is not None
        assert result.get("source") == "OpenWeatherMap"


if __name__ == "__main__":
    pytest.main([__file__, "-v", "--tb=short"])
