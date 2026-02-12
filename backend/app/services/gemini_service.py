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
        acreage: float = 1.0,
        soil_type: str = "Unknown",
        weather_context: Optional[Dict[str, Any]] = None,
        language: Optional[str] = None
    ) -> Dict[str, Any]:
        """Analyze crop disease using Gemini 1.5 Flash (Multimodal + JSON Mode)"""
        try:
            prompt = f"""You are an expert agricultural advisor for Indian farmers. 
Analyze the crop image and the farmer's description to provide a precise diagnosis.
Provide advice that is specifically grounded in the following plot metadata:

PLOT METADATA:
- Scale: {acreage} acres
- Soil Environment: {soil_type}
- Farmer Input: {voice_transcription}
"""
            if language:
                logger.debug(f"Generating crop diagnosis in language: {language}")
                prompt += f"\nLANGUAGE INSTRUCTIONS:\nThe farmer's preferred language is {language}. You MUST provide the 'disease_name', 'treatment_recommendation', and 'prevention' in {language}.\n"
            else:
                prompt += "\nLANGUAGE INSTRUCTIONS:\nYou MUST provide the 'disease_name' and 'treatment_recommendation' in the SAME language as the farmer's description. If not provided or unclear, default to English.\n"

            prompt += """\nProvide your response as a valid JSON object with these EXACT keys:
- disease_name: The name of the disease or pest identified.
- confidence_score: A float between 0 and 1 representing your confidence.
- severity: 'Low', 'Medium', or 'High'.
- treatment_recommendation: Detailed instructions scaled for {acreage} acres on {soil_type}.
- prevention: A list of preventive steps specific to {soil_type} constraints.
- recovery_time: Estimated days to recovery.

CRITICAL PRECISION:
- All chemical or organic quantities MUST be calculated and stated for a {acreage} acre plot.
- Recommendations must account for the drainage and nutrient properties of {soil_type} soil.
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
            analysis_data = self._parse_json(response.text)
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
    # CONVERSATIONAL REFINEMENT (Experience-Led AI)
    # =========================================================================
    async def refine_diagnosis_with_context(
        self,
        original_diagnosis: Dict[str, Any],
        farmer_feedback: str,
        context_overrides: Dict[str, Any],
        interaction_history: Optional[list[Dict[str, Any]]] = None,
        language: Optional[str] = None
    ) -> Dict[str, Any]:
        """
        Refine a diagnosis based on the farmer's ground-truth observations.
        Uses Gemini 3.0 Pro for reasoning.
        """
        try:
            # Build Interaction Thread
            history_text = ""
            if interaction_history:
                history_text = "\\n\\nPREVIOUS INTERACTION THREAD:\\n"
                for item in interaction_history:
                    role = item.get('role', 'unknown').upper()
                    content = item.get('content', '')
                    history_text += f"[{role}]: {content}\\n"
            
            prompt = f"""You are a humble, expert agricultural advisor. A farmer is engaging in a conversation to refine your diagnosis.
            
YOUR GOAL:
Review the 'Original Diagnosis' and the 'Interaction Thread'. 
- Use the thread to understand the evolving context.
- If the new evidence (e.g., 'heavy rain', 'sandy soil') in the thread contradicts your visual analysis, YOU MUST REVISE your diagnosis.
- Trust the farmer's ground-truth observations over your visual inference.
- If the evidence is irrelevant, gently explain why the original diagnosis stands.

Original Diagnosis:
{original_diagnosis}

{history_text}

Latest Feedback (New Evidence):
"{farmer_feedback}"

Context Overrides (Ground Truth):
{context_overrides}
"""
            if language:
                 prompt += f"\\nLANGUAGE INSTRUCTIONS:\\nThe farmer's language is {language}. You MUST translate the CONTENT of 'revised_diagnosis', 'reasoning', and 'treatment_adjustment' into {language}.\\nCRITICAL: Do NOT translate the JSON keys. Keep them exactly as 'revised_diagnosis', 'reasoning', etc.\\n"

            prompt += """
Provide your response as a valid JSON object with these EXACT keys:
- is_revised: boolean (true if you changed the diagnosis).
- revised_diagnosis: The name of the disease (new or original).
- confidence_score: Your new confidence score (0-1).
- reasoning: A polite explanation of why you changed (or kept) the diagnosis, acknowledging the farmer's input.
- treatment_adjustment: Any changes to the treatment plan based on the new context (e.g., "Avoid watering due to rain").
"""

            response = self.model_30_pro.generate_content(
                prompt,
                generation_config={"response_mime_type": "application/json"}
            )
            
            refinement_data = self._parse_json(response.text)
            return {
                "status": "success",
                "refinement": refinement_data,
                "model_used": "gemini-3.0-pro"
            }
        except Exception as e:
            logger.error(f"Refinement failed: {str(e)}")
            return {"status": "error", "error": str(e)}

    # =========================================================================
    # YIELD PREDICTION
    # =========================================================================
    async def predict_yield(
        self,
        crop_data: Dict[str, Any],
        weather_forecast: Dict[str, Any],
        historical_data: Optional[Dict[str, Any]] = None,
        language: Optional[str] = None
    ) -> Dict[str, Any]:
        """Predict crop yield using Gemini 3.0 Pro (Reasoning)"""
        try:
            prompt = f"""You are an agricultural AI advisor using advanced reasoning to predict crop yields.
Crop Information: {crop_data}
Weather Forecast (7 days): {weather_forecast}
"""
            if language:
                logger.debug(f"Generating yield prediction in language: {language}")
                prompt += f"\nLANGUAGE INSTRUCTIONS:\nThe farmer's preferred language is {language}. \n- 'factors' and 'recommendations': MUST be generated in {language}. Do NOT use English for these fields.\n- 'contextual_insights': The fields 'label', 'status', and 'icon_type' MUST remain in ENGLISH. Only 'value' should be translated if applicable.\n"
            
            target_lang_instruction = f"Translated to {language}" if language else "in English"

            prompt += f"""
Using the above data, predict the following:
1. expected_yield: Estimated yield in quintals per acre (float).
2. confidence: Your confidence score from 0 to 100 (float).
3. factors: A list of the top 3-5 factors influencing this prediction ({target_lang_instruction}).
4. recommendations: A list of 3-5 specific actions the farmer should take ({target_lang_instruction}).
5. daily_forecast: A list of 7 objects (one for each day in weather_forecast) containing:
   - day: Short name (e.g., 'Mon').
   - temp: The forecast max temperature for that day.
   - condition: Brief status (e.g., 'Sunny', 'Heavy Rain').
   - yield_potential: A score (0-100) representing how favorable these specific daily conditions are for {crop_data.get('crop_name', 'the crop')}.
6. contextual_insights: A list of exactly 4 objects for the following categories: 'Temperature', 'Soil Moisture', 'Disease Risk', 'Sunlight'. Each object MUST have:
   - label: The category name IN ENGLISH (e.g., 'Temperature').
   - value: A specific value (e.g., '23.9°C', 'High', 'Moderate', 'Diffuse').
   - status: One of 'Optimal', 'Monitor', 'Warning', 'Good' (IN ENGLISH).
   - icon_type: One of 'thermometer', 'droplet', 'warning', 'sun' (IN ENGLISH).

Return your response as a valid JSON object.
"""
            if language:
                prompt += f"\nCRITICAL INSTRUCTION: The user provided their language as '{language}'. You MUST translate the content of 'factors' and 'recommendations' into {language}. Do NOT return them in English."
            if historical_data:
                prompt += f"Historical Yield Data:\n{historical_data}\n\n"
            
            import json
            import time
            start_time = time.time()
            logger.debug(f"🚀 Starting Yield Prediction with Gemini 3 Pro...")
            
            response = self.model_30_pro.generate_content(
                prompt,
                generation_config={"response_mime_type": "application/json"}
            )
            
            duration = time.time() - start_time
            logger.info(f"✅ Yield Prediction finished in {duration:.2f} seconds.")
            
            prediction_data = self._parse_json(response.text)
            return {
                "status": "success",
                "prediction": prediction_data,
                "model_used": "gemini-3.0-pro"
            }
        except Exception as e:
            logger.error(f"3.0 Pro yield prediction failed: {str(e)}")
            return {"status": "error", "error": str(e)}

    # =========================================================================
    # VERSION 3.0: YIELD PREDICTION (Legacy/Preview)
    # =========================================================================
    async def predict_yield_v3(
        self,
        crop_data: Dict[str, Any],
        weather_forecast: Dict[str, Any],
        historical_data: Optional[Dict[str, Any]] = None,
        language: Optional[str] = None
    ) -> Dict[str, Any]:
        """Predict crop yield using Gemini 3.0 Pro (Reasoning)"""
        try:
            prompt = f"""You are an agricultural AI advisor using advanced reasoning to predict crop yields.
"""
            if language:
                prompt += f"\nLANGUAGE PREFERENCE: The farmer's preferred language is {language}. You MUST provide ALL text fields (factors, recommendations) in {language}. Do NOT use English.\n"
            
            prompt += f"""
Crop Information:
- Type: {crop_data.get('crop_name')}
- Area: {crop_data.get('field_area')} acres
- Planted: {crop_data.get('planted_date')}
- Expected Harvest: {crop_data.get('expected_harvest_date', 'Not specified')}
- Soil Type: {crop_data.get('soil_type', 'Unknown')}

Weather Forecast (7 days):
{weather_forecast}

Using step-by-step reasoning, predict:
1. expected_yield: Estimated yield in quintals per acre (float).
2. confidence: Your confidence score from 0 to 100 (float).
3. factors: A list of the top 3-5 factors influencing this prediction.
4. recommendations: A list of 3-5 specific actions the farmer should take.

Return your response as a valid JSON object.
"""
            if historical_data:
                prompt += f"Historical Yield Data:\n{historical_data}\n\n"
            
            import json
            response = self.model_30_pro.generate_content(
                prompt,
                generation_config={"response_mime_type": "application/json"}
            )
            
            prediction_data = json.loads(response.text)
            return {
                "status": "success",
                "prediction": prediction_data,
                "model_used": "gemini-3.0-pro"
            }
        except Exception as e:
            return {"status": "error", "error": str(e)}

    # =========================================================================
    # UTILITIES
    # =========================================================================
    def _parse_json(self, response_text: str) -> Dict[str, Any]:
        """Robusly parse JSON from Gemini's response, stripping markdown backticks if present."""
        try:
            cleaned_text = response_text.strip()
            if cleaned_text.startswith("```"):
                # Handle ```json ... ``` or just ``` ... ```
                if cleaned_text.startswith("```json"):
                    cleaned_text = cleaned_text[7:]
                else:
                    cleaned_text = cleaned_text[3:]
                
                if cleaned_text.endswith("```"):
                    cleaned_text = cleaned_text[:-3]
                
                cleaned_text = cleaned_text.strip()
            
            import json
            return json.loads(cleaned_text)
        except Exception as e:
            logger.error(f"JSON Parsing failed: {str(e)} | Text: {response_text[:200]}")
            raise ValueError(f"Failed to parse valid JSON from AI response: {str(e)}")

    async def translate_text(self, text: str, target_language: str) -> Dict[str, Any]:
        """Translate text using Gemini 1.5 Flash (Fast & Cheap)"""
        try:
            prompt = f"""Translate the following text to {target_language}. 
Maintain the original tone and technical accuracy. Return ONLY the translated text.

Text to translate:
{text}
"""
            response = self.model_15_flash.generate_content(prompt)
            return {"status": "success", "translation": response.text.strip()}
        except Exception as e:
            logger.error(f"Translation failed: {str(e)}")
            return {"status": "error", "error": str(e)}
# Re-syncing for revert
