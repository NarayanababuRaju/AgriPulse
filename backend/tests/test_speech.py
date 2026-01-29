import asyncio
import os
from dotenv import load_dotenv

# Load environment variables (including GOOGLE_APPLICATION_CREDENTIALS)
load_dotenv(os.path.join(os.path.dirname(__file__), "../.env"))

from app.services.speech_service import SpeechService

# MOCK testing script since we might not have a mic input here
# This tests the SERVICE class logic, not the API endpoint

async def test_speech_service():
    print("🎙️ Testing Speech Service Components")
    print("=" * 60)
    
    service = SpeechService()
    
    # 1. Test Text-to-Speech (Synthesis)
    print("\n1️⃣ Testing TTS (Speaking)...")
    text = "Hello farmer, this is a test of the AgriPulse voice system."
    try:
        audio_data = await service.synthesize_speech(text, "en-IN")
        print(f"✅ TTS Success! Generated {len(audio_data)} bytes of audio.")
        # Optional: verify first bytes match MP3 header
        
        # Save to a file for manual verification if needed
        # with open("test_output.mp3", "wb") as f:
        #     f.write(audio_data)
        
    except Exception as e:
        print(f"❌ TTS Failed (Expected if credentials invalid): {e}")

    # 2. Test Speech-to-Text (Transcription)
    print("\n2️⃣ Testing STT (Listening)...")
    try:
        # We need a dummy audio payload. 
        # In a real test, we'd load a small .wav file.
        # Sending random bytes will cause an API error, but verifies the connection.
        mock_audio = b"not_real_audio_data" 
        
        result = await service.transcribe_audio(mock_audio, "en-IN")
        print(f"📝 Result: {result}")
        
    except Exception as e:
        print(f"❌ STT Failed: {e}")

if __name__ == "__main__":
    asyncio.run(test_speech_service())
