from fastapi import APIRouter, UploadFile, File, Form, HTTPException
from pydantic import BaseModel
from typing import Optional, Dict, Any
from app.services.gemini_service import GeminiService
from app.services.database_service import FirestoreService
from loguru import logger

router = APIRouter(prefix="/api/crop", tags=["Crop Analysis"])

# Initialize services
gemini_service = GeminiService()
db_service = FirestoreService()


class AnalysisResponse(BaseModel):
    analysis_id: str
    diagnosis: str
    confidence: float
    recommendations: Dict[str, Any]


@router.post("/analyze", response_model=Dict[str, Any])
async def analyze_crop(
    farmer_id: str = Form(...),
    image: UploadFile = File(...),
    voice_transcription: str = Form(...),
    weather_context: Optional[str] = Form(None),
    language: Optional[str] = Form(None)
):
    """
    Analyze crop disease from image and voice input
    
    - **farmer_id**: Farmer's unique ID
    - **image**: Crop photo (JPEG/PNG)
    - **voice_transcription**: Farmer's description in local language
    - **weather_context**: Optional weather data (JSON string)
    """
    try:
        logger.debug(f"Received crop analysis request from farmer: {farmer_id}")
        logger.debug(f"Voice transcription: {voice_transcription}")
        logger.debug(f"Weather context: {weather_context}")
        
        # Read image data
        image_data = await image.read()
        logger.debug(f"Image read successfully, size: {len(image_data)} bytes")
        
        # Parse weather context if provided
        weather_dict = None
        if weather_context:
            import json
            try:
                weather_dict = json.loads(weather_context)
                logger.debug(f"Parsed weather context: {weather_dict}")
            except Exception as je:
                logger.warning(f"Failed to parse weather context JSON: {je}. Context was: {weather_context}")
        
        # Call Gemini service
        result = await gemini_service.analyze_crop_disease(
            image_data=image_data,
            voice_transcription=voice_transcription,
            weather_context=weather_dict,
            language=language
        )
        
        if result["status"] == "error":
            raise HTTPException(status_code=500, detail=result["error"])
        
        # Save to Firestore
        analysis_id = await db_service.save_analysis(
            farmer_id=farmer_id,
            analysis_data={
                "type": "disease_analysis",
                "voice_transcription": voice_transcription,
                "gemini_response": result["analysis"],
                "model_used": result["model_used"]
            }
        )
        
        logger.info(f"Analysis completed for farmer {farmer_id}: {analysis_id}")
        
        return {
            "status": "success",
            "analysis_id": analysis_id,
            "model": result["model_used"],
            **result["analysis"] # Flatten Gemini analysis fields
        }
        
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Crop analysis endpoint failed: {str(e)}")
        raise HTTPException(status_code=500, detail=str(e))


@router.post("/predict-yield")
async def predict_yield(
    farmer_id: str = Form(...),
    crop_name: str = Form(...),
    field_area: float = Form(...),
    planted_date: str = Form(...),
    soil_type: str = Form(...),
    weather_forecast: str = Form(...),
    expected_harvest_date: Optional[str] = Form(None),
    language: Optional[str] = Form(None)
):
    """
    Predict crop yield using Gemini Pro reasoning
    
    - **farmer_id**: Farmer's unique ID
    - **crop_name**: Type of crop
    - **field_area**: Field size in acres
    - **planted_date**: When crop was planted
    - **soil_type**: Soil classification
    - **weather_forecast**: 7-day forecast (JSON string)
    """
    try:
        import json
        
        crop_data = {
            "crop_name": crop_name,
            "field_area": field_area,
            "planted_date": planted_date,
            "expected_harvest_date": expected_harvest_date,
            "soil_type": soil_type
        }
        
        weather_dict = json.loads(weather_forecast)
        
        # Call Gemini Pro for yield prediction
        result = await gemini_service.predict_yield(
            crop_data=crop_data,
            weather_forecast=weather_dict,
            language=language
        )
        
        if result["status"] == "error":
            raise HTTPException(status_code=500, detail=result["error"])
        
        # Save prediction
        prediction_id = await db_service.save_prediction(
            farmer_id=farmer_id,
            prediction_data={
                "crop_data": crop_data,
                "gemini_response": result["prediction"],
                "model_used": result["model_used"]
            }
        )
        
        logger.info(f"Yield prediction completed for farmer {farmer_id}: {prediction_id}")
        
        return {
            "status": "success",
            "prediction_id": prediction_id,
            "result": result["prediction"],
            "model": result["model_used"]
        }
        
    except Exception as e:
        logger.error(f"Yield prediction endpoint failed: {str(e)}")
        raise HTTPException(status_code=500, detail=str(e))
