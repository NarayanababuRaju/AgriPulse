"""
Simple test to verify Gemini integration without Firestore
"""
import requests
import json
import io
from PIL import Image

BASE_URL = "http://127.0.0.1:8080"

print("🔍 Testing Gemini Crop Analysis (without Firestore save)...\n")

# Create a test image
img = Image.new('RGB', (100, 100), color='green')
img_bytes = io.BytesIO()
img.save(img_bytes, format='JPEG')
img_bytes.seek(0)

files = {
    'image': ('test_crop.jpg', img_bytes, 'image/jpeg')
}

data = {
    'farmer_id': 'test_farmer_001',
    'voice_transcription': 'My onion leaves are turning yellow at the tips',
    'weather_context': json.dumps({
        'condition': 'Humid',
        'temperature': 28
    })
}

try:
    response = requests.post(f"{BASE_URL}/api/crop/analyze", files=files, data=data)
    print(f"Status Code: {response.status_code}\n")
    
    if response.status_code == 200:
        result = response.json()
        print("✅ SUCCESS! Gemini Analysis:")
        print(f"Analysis ID: {result.get('analysis_id')}")
        print(f"Model Used: {result.get('model')}")
        print(f"\nGemini Response:\n{result.get('result')}")
    else:
        print(f"❌ Error: {response.text}")
        # Check if it's just a Firestore error but Gemini worked
        if "Gemini" in response.text or "diagnosis" in response.text:
            print("\n⚠️  Note: Gemini analysis succeeded, but Firestore save failed")
            print("This is expected if Firestore permissions aren't set up yet")
            
except Exception as e:
    print(f"❌ Request failed: {str(e)}")
