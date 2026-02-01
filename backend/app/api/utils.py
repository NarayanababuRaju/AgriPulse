from fastapi import APIRouter, Form, HTTPException
from app.services.gemini_service import GeminiService
from loguru import logger
from typing import Dict, Any

router = APIRouter(prefix="/api/utils", tags=["Utilities"])

gemini_service = GeminiService()

@router.post("/translate", response_model=Dict[str, Any])
async def translate_text(
    text: str = Form(...),
    target_language: str = Form(...)
):
    """
    Translate text using Gemini 1.5 Flash
    """
    try:
        logger.debug(f"Translating text to {target_language}")
        result = await gemini_service.translate_text(text, target_language)
        
        if result["status"] == "error":
            raise HTTPException(status_code=500, detail=result["error"])
            
        return {
            "status": "success",
            "translation": result["translation"]
        }
    except Exception as e:
        logger.error(f"Translation endpoint failed: {str(e)}")
        raise HTTPException(status_code=500, detail=str(e))
