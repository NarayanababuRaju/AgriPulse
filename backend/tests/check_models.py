"""
Diagnostic script to check available Gemini models
"""
import google.generativeai as genai
from app.core.config import get_settings

settings = get_settings()
genai.configure(api_key=settings.gemini_api_key)

print("🔍 Checking available Gemini models...\n")

try:
    models = genai.list_models()
    print("✅ Available models:")
    for model in models:
        if 'generateContent' in model.supported_generation_methods:
            print(f"  - {model.name}")
            print(f"    Display name: {model.display_name}")
            print(f"    Methods: {model.supported_generation_methods}\n")
except Exception as e:
    print(f"❌ Error listing models: {e}")
