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
        
        # --- Gemini 1.5 Models (Stable/Production) ---
        # Note: Using aliases 'gemini-flash-latest' as 'gemini-1.5-flash' was not found in list_models
        self.model_15_flash = genai.GenerativeModel('gemini-flash-latest')
        self.model_15_pro = genai.GenerativeModel('gemini-pro-latest')
        
        # --- Gemini 3.0 Models (Experimental/Preview) ---
        self.model_30_flash = genai.GenerativeModel('gemini-3-flash-preview')
        self.model_30_pro = genai.GenerativeModel('gemini-3-pro-preview')
        
        logger.info("Gemini service initialized with both 1.5 and 3.0 model families.")

    # =========================================================================
    # VERSION 1.5: CROP ANALYSIS (Current default for stability)
    # =========================================================================
    async def analyze_crop_disease(
        self,
        image_data: bytes,
        voice_transcription: str,
        weather_context: Optional[Dict[str, Any]] = None,
        language: Optional[str] = None
    ) -> Dict[str, Any]:
        """Analyze crop disease using Gemini 1.5 Flash (Multimodal + JSON Mode)"""
        try:
            prompt = f"""You are an expert agricultural advisor for Indian farmers. 
Analyze the crop image and the farmer's description to provide a precise diagnosis.

Farmer's Description: {voice_transcription}
"""
            if language:
                prompt += f"LANGUAGE PREFERENCE: The farmer's preferred language is {language}. HOWEVER, you MUST respond in the SAME language used in the 'Farmer's Description' above. If the description is in English, respond in English. Use {language} only if the description is missing or its language is unclear.\n"
            else:
                prompt += "IMPORTANT: You MUST provide the 'disease_name' and 'treatment_recommendation' in the SAME language as the farmer's description. If not provided, default to English.\n"

            prompt += """\nProvide your response as a valid JSON object with these EXACT keys:
- disease_name: The name of the disease or pest identified.
- confidence_score: A float between 0 and 1 representing your confidence.
- severity: 'Low', 'Medium', or 'High'.
- treatment_recommendation: A comprehensive guide including both organic and chemical options.
- prevention: A list of preventive steps.
- recovery_time: Estimated days to recovery.
"""
            
            logger.debug(f"Calling Gemini with prompt: {prompt[:500]}...")
            
            import json
            # Use base64 for more reliable data transfer in some SDK versions
            image_part = {
                "mime_type": "image/jpeg",
                "data": image_data
            }
            
            response = self.model_15_flash.generate_content(
                [prompt, image_part],
                generation_config={"response_mime_type": "application/json"}
            )
            
            logger.debug(f"Gemini response received: {response.text[:200]}...")
            analysis_data = json.loads(response.text)
            return {
                "status": "success",
                "analysis": analysis_data,
                "model_used": "gemini-1.5-flash"
            }
        except Exception as e:
            logger.error(f"1.5 Flash analysis failed: {str(e)}")
            return {"status": "error", "error": str(e)}

    # =========================================================================
    # VERSION 3.0: CROP ANALYSIS (Legacy/Preview)
    # =========================================================================
    async def analyze_crop_disease_v3(
        self,
        image_data: bytes,
        voice_transcription: str,
        weather_context: Optional[Dict[str, Any]] = None
    ) -> Dict[str, Any]:
        """Analyze crop disease using Gemini 3.0 Flash (Preview)"""
        try:
            prompt = f"""You are an expert agricultural advisor for Indian farmers.
Farmer's Description: {voice_transcription}

Analyze the crop image and provide:
1. Disease/Pest Identification (with confidence %)
2. Severity Level (Low/Medium/High)
3. Organic Treatment Options (with cost estimates in ₹)
4. Chemical Treatment Options (with cost estimates in ₹)
5. Preventive Measures
6. Expected Recovery Time

Format your response as JSON with these exact keys:
{{
  "diagnosis": "disease name",
  "confidence": 95,
  "severity": "Medium",
  "organic_treatments": [{{ "name": "...", "cost": "₹...", "application": "..." }}],
  "chemical_treatments": [{{ "name": "...", "cost": "₹...", "application": "..." }}],
  "prevention": ["...", "..."],
  "recovery_time": "7-10 days"
}}"""
            
            response = self.model_30_flash.generate_content([
                prompt,
                {"mime_type": "image/jpeg", "data": image_data}
            ])
            
            return {
                "status": "success",
                "analysis": response.text,
                "model_used": "gemini-3.0-flash"
            }
        except Exception as e:
            logger.error(f"3.0 Flash analysis failed: {str(e)}")
            return {"status": "error", "error": str(e)}

    # =========================================================================
    # YIELD PREDICTION
    # =========================================================================
    async def predict_yield(
        self,
        crop_data: Dict[str, Any],
        weather_forecast: Dict[str, Any],
        historical_data: Optional[Dict[str, Any]] = None
    ) -> Dict[str, Any]:
        """Predict crop yield using Gemini 1.5 Pro (Reasoning)"""
        try:
            prompt = f"""You are an agricultural AI advisor using advanced reasoning to predict crop yields.
Crop Information: {crop_data}
Weather Forecast (7 days): {weather_forecast}
"""
            if historical_data:
                prompt += f"Historical Yield Data:\n{historical_data}\n\n"
            
            prompt += """Predict: Expected yield (quintals/acre), confidence, and factors. Return JSON."""
            
            response = self.model_15_pro.generate_content(prompt)
            return {
                "status": "success",
                "prediction": response.text,
                "model_used": "gemini-1.5-pro"
            }
        except Exception as e:
            logger.error(f"1.5 Pro yield prediction failed: {str(e)}")
            return {"status": "error", "error": str(e)}

    # =========================================================================
    # VERSION 3.0: YIELD PREDICTION (Legacy/Preview)
    # =========================================================================
    async def predict_yield_v3(
        self,
        crop_data: Dict[str, Any],
        weather_forecast: Dict[str, Any],
        historical_data: Optional[Dict[str, Any]] = None
    ) -> Dict[str, Any]:
        """Predict crop yield using Gemini 3.0 Pro (Reasoning)"""
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
            
            prompt += """Using step-by-step reasoning, predict yield. Return JSON."""
            
            response = self.model_30_pro.generate_content(prompt)
            return {
                "status": "success",
                "prediction": response.text,
                "model_used": "gemini-3.0-pro"
            }
        except Exception as e:
            logger.error(f"3.0 Pro yield prediction failed: {str(e)}")
            return {"status": "error", "error": str(e)}
