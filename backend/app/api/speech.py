from fastapi import APIRouter, UploadFile, File, Form, HTTPException
from fastapi.responses import StreamingResponse
from app.services.speech_service import SpeechService
from typing import Dict, Any
import io

router = APIRouter(prefix="/api/speech", tags=["Speech"])
speech_service = SpeechService()

@router.post("/transcribe", response_model=Dict[str, Any])
async def transcribe_audio(
    file: UploadFile = File(...),
    language: str = Form("en-IN", description="Language code (e.g., ta, pa, hi)")
):
    """
    Convert uploaded audio file to text.
    Acts as the 'Ears' of the Intelligence Layer.
    """
    try:
        audio_content = await file.read()
        
        # Map simple language codes to full BCP-47 codes if needed
        # (The service handles this mapping, but we can do validation here)
        
        text = await speech_service.transcribe_audio(audio_content, language_code=language)
        
        return {
            "transcription": text,
            "detected_language": language,
            "status": "success"
        }
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@router.post("/synthesize")
async def synthesize_speech(
    text: str = Form(...),
    language: str = Form("en-IN")
):
    """
    Convert text to speech audio.
    Acts as the 'Mouth' of the Intelligence Layer.
    Returns: Streamed MP3 audio.
    """
    try:
        audio_bytes = await speech_service.synthesize_speech(text, language_code=language)
        
        return StreamingResponse(
            io.BytesIO(audio_bytes),
            media_type="audio/mpeg"
        )
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))
