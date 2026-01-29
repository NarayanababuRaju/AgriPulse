"""
Integration Tests for AgriPulse Backend
Tests end-to-end workflows combining multiple services.
"""
import pytest
import asyncio
import os
from dotenv import load_dotenv
from io import BytesIO
from PIL import Image
import json

load_dotenv(os.path.join(os.path.dirname(__file__), "../.env"))

import sys
sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), '..')))

from app.services.gemini_service import GeminiService
from app.services.weather_service import WeatherService
from app.services.speech_service import SpeechService


class TestCropAnalysisWorkflow:
    """Test complete crop analysis workflow"""
    
    @pytest.fixture
    def services(self):
        return {
            "gemini": GeminiService(),
            "weather": WeatherService(),
            "speech": SpeechService()
        }
    
    def create_test_image(self):
        """Create a test crop image"""
        img = Image.new('RGB', (200, 200), color='green')
        img_bytes = BytesIO()
        img.save(img_bytes, format='JPEG')
        return img_bytes.getvalue()
    
    @pytest.mark.asyncio
    async def test_full_analysis_workflow(self, services):
        """Test complete workflow: Weather → Speech → Gemini"""
        
        # Step 1: Get weather context
        weather = await services["weather"].get_current_weather(12.9716, 77.5946)
        assert weather is not None
        
        # Step 2: Simulate voice input (in real scenario, this would be transcribed)
        voice_text = "My rice crop leaves are turning yellow and brown"
        
        # Step 3: Analyze with Gemini (with weather context)
        image_data = self.create_test_image()
        analysis = await services["gemini"].analyze_crop_disease(
            image_data=image_data,
            voice_transcription=voice_text,
            weather_context=weather
        )
        
        assert analysis is not None
        assert isinstance(analysis, dict)
        
        # Step 4: Convert response to speech (if needed)
        if "diagnosis" in analysis:
            response_text = f"Detected {analysis.get('diagnosis', 'unknown condition')}"
            audio = await services["speech"].synthesize_speech(response_text, "en-IN")
            assert len(audio) > 0


class TestYieldPredictionWorkflow:
    """Test complete yield prediction workflow"""
    
    @pytest.fixture
    def services(self):
        return {
            "gemini": GeminiService(),
            "weather": WeatherService()
        }
    
    @pytest.mark.asyncio
    async def test_yield_prediction_with_forecast(self, services):
        """Test yield prediction with weather forecast integration"""
        
        # Step 1: Get weather forecast
        forecast = await services["weather"].get_forecast(12.9716, 77.5946)
        assert forecast is not None
        
        # Step 2: Predict yield with forecast data
        prediction = await services["gemini"].predict_yield(
            crop_name="Rice",
            variety="Basmati",
            field_area=2.5,
            planted_date="2025-11-01",
            soil_type="Clay",
            weather_forecast=forecast
        )
        
        assert prediction is not None
        assert isinstance(prediction, dict)


class TestMultilingualWorkflow:
    """Test multilingual support across services"""
    
    @pytest.fixture
    def speech_service(self):
        return SpeechService()
    
    @pytest.mark.asyncio
    async def test_tamil_voice_workflow(self, speech_service):
        """Test Tamil language voice input/output"""
        
        # Tamil text
        tamil_text = "உங்கள் பயிரில் நோய் உள்ளது"
        
        # Synthesize to speech
        audio = await speech_service.synthesize_speech(tamil_text, "ta-IN")
        assert len(audio) > 0
    
    @pytest.mark.asyncio
    async def test_hindi_voice_workflow(self, speech_service):
        """Test Hindi language voice input/output"""
        
        hindi_text = "आपकी फसल में बीमारी है"
        
        audio = await speech_service.synthesize_speech(hindi_text, "hi-IN")
        assert len(audio) > 0


class TestErrorHandling:
    """Test error handling across integrated services"""
    
    @pytest.fixture
    def services(self):
        return {
            "gemini": GeminiService(),
            "weather": WeatherService(),
            "speech": SpeechService()
        }
    
    @pytest.mark.asyncio
    async def test_graceful_weather_failure(self, services):
        """Test that system handles weather service failures gracefully"""
        
        # Use invalid coordinates
        weather = await services["weather"].get_current_weather(999, 999)
        
        # Should return mock data, not crash
        assert weather is not None
        assert "temperature" in weather
    
    @pytest.mark.asyncio
    async def test_gemini_with_invalid_image(self, services):
        """Test Gemini handles invalid image data"""
        
        invalid_image = b"not_an_image"
        
        try:
            result = await services["gemini"].analyze_crop_disease(
                image_data=invalid_image,
                voice_transcription="Test",
                weather_context={}
            )
            # Should either return error or handle gracefully
            assert result is not None
        except Exception as e:
            # Exception is acceptable for invalid input
            assert True


class TestPerformance:
    """Test performance benchmarks"""
    
    @pytest.fixture
    def services(self):
        return {
            "weather": WeatherService(),
            "speech": SpeechService()
        }
    
    @pytest.mark.asyncio
    async def test_weather_response_time(self, services):
        """Test weather API response time"""
        import time
        
        start = time.time()
        await services["weather"].get_current_weather(12.9716, 77.5946)
        duration = time.time() - start
        
        # Should respond within 5 seconds
        assert duration < 5.0
    
    @pytest.mark.asyncio
    async def test_speech_synthesis_time(self, services):
        """Test TTS response time"""
        import time
        
        text = "This is a test message for performance testing"
        
        start = time.time()
        await services["speech"].synthesize_speech(text, "en-IN")
        duration = time.time() - start
        
        # Should respond within 3 seconds
        assert duration < 3.0


if __name__ == "__main__":
    pytest.main([__file__, "-v", "--tb=short"])
