"""
Test script for AgriPulse Backend API
Tests the Gemini integration and API endpoints
"""
import requests
import json
from pathlib import Path

BASE_URL = "http://127.0.0.1:8080"

def test_health():
    """Test health endpoint"""
    print("🔍 Testing /health endpoint...")
    response = requests.get(f"{BASE_URL}/health")
    print(f"✅ Status: {response.status_code}")
    print(f"   Response: {response.json()}\n")
    return response.status_code == 200

def test_root():
    """Test root endpoint"""
    print("🔍 Testing / endpoint...")
    response = requests.get(f"{BASE_URL}/")
    print(f"✅ Status: {response.status_code}")
    print(f"   Response: {json.dumps(response.json(), indent=2)}\n")
    return response.status_code == 200

def test_crop_analysis():
    """Test crop analysis endpoint with a sample image"""
    print("🔍 Testing /api/crop/analyze endpoint...")
    
    # Create a simple test image (1x1 pixel)
    import io
    from PIL import Image
    
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
        print(f"✅ Status: {response.status_code}")
        if response.status_code == 200:
            result = response.json()
            print(f"   Analysis ID: {result.get('analysis_id')}")
            print(f"   Model Used: {result.get('model')}")
            print(f"   Result Preview: {result.get('result')[:200]}...\n")
        else:
            print(f"   Error: {response.text}\n")
        return response.status_code == 200
    except Exception as e:
        print(f"❌ Error: {str(e)}\n")
        return False

if __name__ == "__main__":
    print("=" * 60)
    print("🚀 AgriPulse Backend API Test Suite")
    print("=" * 60 + "\n")
    
    # Check if server is running
    try:
        requests.get(BASE_URL, timeout=2)
    except requests.exceptions.ConnectionError:
        print("❌ Server is not running!")
        print("   Please start the server with: uvicorn app.main:app --reload")
        exit(1)
    
    # Run tests
    results = {
        "Health Check": test_health(),
        "Root Endpoint": test_root(),
        "Crop Analysis (Gemini)": test_crop_analysis()
    }
    
    # Summary
    print("=" * 60)
    print("📊 Test Summary")
    print("=" * 60)
    for test_name, passed in results.items():
        status = "✅ PASSED" if passed else "❌ FAILED"
        print(f"{test_name}: {status}")
    
    total = len(results)
    passed = sum(results.values())
    print(f"\nTotal: {passed}/{total} tests passed")
