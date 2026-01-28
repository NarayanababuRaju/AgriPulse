import google.generativeai as genai
from typing import Optional, Dict, Any
from app.core.config import get_settings
from loguru import logger
import base64


class GeminiService:
    """Service for interacting with Gemini 3 API"""
    
    def __init__(self):
        settings = get_settings()
        genai.configure(api_key=settings.gemini_api_key)
        
        # Initialize models - using Gemini 3 Preview (latest available)
        self.flash_model = genai.GenerativeModel('gemini-3-flash-preview')
        self.pro_model = genai.GenerativeModel('gemini-3-pro-preview')
        
        logger.info("Gemini service initialized with 3.0 Flash and Pro models")
    
    async def analyze_crop_disease(
        self,
        image_data: bytes,
        voice_transcription: str,
        weather_context: Optional[Dict[str, Any]] = None
    ) -> Dict[str, Any]:
        """
        Analyze crop disease using Gemini 3 Flash (multimodal)
        
        Args:
            image_data: Crop image bytes
            voice_transcription: Farmer's description in local language
            weather_context: Optional weather data for context
        
        Returns:
            Disease analysis with recommendations
        """
        try:
            # Prepare multimodal prompt
            prompt = f"""You are an expert agricultural advisor for Indian farmers.

Farmer's Description: {voice_transcription}

"""
            if weather_context:
                prompt += f"Current Weather: {weather_context.get('condition', 'N/A')}, Temperature: {weather_context.get('temperature', 'N/A')}°C\n\n"
            
            prompt += """Analyze the crop image and provide:
1. Disease/Pest Identification (with confidence %)
2. Severity Level (Low/Medium/High)
3. Organic Treatment Options (with cost estimates in ₹)
4. Chemical Treatment Options (with cost estimates in ₹)
5. Preventive Measures
6. Expected Recovery Time

Format your response as JSON with these exact keys:
{
  "diagnosis": "disease name",
  "confidence": 95,
  "severity": "Medium",
  "organic_treatments": [{"name": "...", "cost": "₹...", "application": "..."}],
  "chemical_treatments": [{"name": "...", "cost": "₹...", "application": "..."}],
  "prevention": ["...", "..."],
  "recovery_time": "7-10 days"
}"""
            
            # Generate response with image
            response = self.flash_model.generate_content([
                prompt,
                {"mime_type": "image/jpeg", "data": image_data}
            ])
            
            logger.info(f"Crop analysis completed: {response.text[:100]}...")
            
            return {
                "status": "success",
                "analysis": response.text,
                "model_used": "gemini-3.0-flash"
            }
            
        except Exception as e:
            logger.error(f"Crop analysis failed: {str(e)}")
            return {
                "status": "error",
                "error": str(e)
            }
    
    async def predict_yield(
        self,
        crop_data: Dict[str, Any],
        weather_forecast: Dict[str, Any],
        historical_data: Optional[Dict[str, Any]] = None
    ) -> Dict[str, Any]:
        """
        Predict crop yield using Gemini 3 Pro (reasoning mode)
        
        Args:
            crop_data: Current crop information
            weather_forecast: 7-day weather prediction
            historical_data: Optional past yield data
        
        Returns:
            Yield prediction with reasoning breakdown
        """
        try:
            prompt = f"""You are an agricultural AI advisor using advanced reasoning to predict crop yields.

Crop Information:
- Type: {crop_data.get('crop_name')}
- Area: {crop_data.get('field_area')} acres
- Planted: {crop_data.get('planted_date')}
- Soil Type: {crop_data.get('soil_type', 'Unknown')}

Weather Forecast (7 days):
{weather_forecast}

"""
            if historical_data:
                prompt += f"Historical Yield Data:\n{historical_data}\n\n"
            
            prompt += """Using step-by-step reasoning, predict:
1. Expected yield (in quintals/acre)
2. Confidence level (%)
3. Factor breakdown (weather impact, soil health, treatment effectiveness)
4. Recommendations to maximize yield

Provide your reasoning process, then give a JSON response:
{
  "predicted_yield": 45.5,
  "confidence": 82,
  "factors": {
    "weather_impact": "+10%",
    "soil_health": "Good",
    "treatment_effectiveness": "+5%"
  },
  "recommendations": ["...", "..."],
  "reasoning_steps": ["Step 1: ...", "Step 2: ..."]
}"""
            
            # Use Pro model with reasoning
            response = self.pro_model.generate_content(prompt)
            
            logger.info(f"Yield prediction completed")
            
            return {
                "status": "success",
                "prediction": response.text,
                "model_used": "gemini-3.0-pro"
            }
            
        except Exception as e:
            logger.error(f"Yield prediction failed: {str(e)}")
            return {
                "status": "error",
                "error": str(e)
            }
