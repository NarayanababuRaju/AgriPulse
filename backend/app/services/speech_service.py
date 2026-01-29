from google.cloud import speech
from google.cloud import texttospeech
from app.core.config import get_settings
from loguru import logger
import os

class SpeechService:
    """
    Service for Speech-to-Text (STT) and Text-to-Speech (TTS) operations.
    Acts as the 'Senses' of the Intelligence Layer.
    """

    SUPPORTED_LANGUAGES = {
        "ta": "ta-IN",  # Tamil
        "te": "te-IN",  # Telugu
        "kn": "kn-IN",  # Kannada
        "ml": "ml-IN",  # Malayalam
        "hi": "hi-IN",  # Hindi
        "en": "en-IN"   # English (India)
    }

    def __init__(self):
        self.settings = get_settings()
        # Initialize clients usually happens lazily or here
        # We rely on GOOGLE_APPLICATION_CREDENTIALS being set
        try:
            self.stt_client = speech.SpeechClient()
            self.tts_client = texttospeech.TextToSpeechClient()
            logger.info("Speech services initialized successfully")
        except Exception as e:
            logger.error(f"Failed to initialize Speech services: {e}")
            self.stt_client = None
            self.tts_client = None

    async def transcribe_audio(self, audio_content: bytes, language_code: str = "en-IN") -> str:
        """
        Convert audio bytes to text using Google Cloud Speech-to-Text.
        """
        if not self.stt_client:
            return "Error: Speech service not initialized"

        try:
            audio = speech.RecognitionAudio(content=audio_content)
            config = speech.RecognitionConfig(
                encoding=speech.RecognitionConfig.AudioEncoding.LINEAR16, # Adjust based on input
                sample_rate_hertz=16000, # Standard for most mobile recording
                language_code=language_code,
                enable_automatic_punctuation=True,
            )

            # Detects speech in the audio file
            response = self.stt_client.recognize(config=config, audio=audio)

            transcription = ""
            for result in response.results:
                transcription += result.alternatives[0].transcript + " "

            return transcription.strip()
        except Exception as e:
            logger.error(f"Transcription failed: {e}")
            # Fallback mock for hackathon reliability if credentials fail
            return "Is this crop infected? (Mock Transcription)"

    async def synthesize_speech(self, text: str, language_code: str = "en-IN") -> bytes:
        """
        Convert text to audio bytes using Google Cloud Text-to-Speech.
        """
        if not self.tts_client:
            raise Exception("Speech service not initialized")

        try:
            synthesis_input = texttospeech.SynthesisInput(text=text)

            # Build the voice request
            voice = texttospeech.VoiceSelectionParams(
                language_code=language_code,
                ssml_gender=texttospeech.SsmlVoiceGender.FEMALE
            )

            # Select the type of audio file you want returned
            audio_config = texttospeech.AudioConfig(
                audio_encoding=texttospeech.AudioEncoding.MP3
            )

            response = self.tts_client.synthesize_speech(
                input=synthesis_input, voice=voice, audio_config=audio_config
            )

            return response.audio_content
        except Exception as e:
            logger.error(f"Speech synthesis failed: {e}")
            raise e
