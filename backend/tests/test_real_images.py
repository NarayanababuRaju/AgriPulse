"""
Real-world test using actual onion disease images
Tests Gemini's ability to diagnose different onion diseases
"""
import requests
import json
import os
from pathlib import Path

BASE_URL = "http://127.0.0.1:8080"
DATA_DIR = Path("../data/raw")

# Disease categories in the dataset
DISEASES = {
    "BasalRot": "Basal Rot - fungal disease affecting onion bulbs",
    "DownyMildew": "Downy Mildew - causes downy growth on leaves",
    "LeafBlight": "Leaf Blight - white specks and infected bulbs",
    "PurpleBlotch": "Purple Blotch - concentric rings and spots",
    "PythiumRootRot": "Pythium Root Rot - damping off and rotted roots",
    "Smut": "Smut - black mass on bulbs",
    "WhiteRot": "White Rot - rotted bulbs with white fungal growth"
}

def test_disease_image(disease_name, image_path):
    """Test a single disease image"""
    print(f"\n{'='*70}")
    print(f"🔬 Testing: {disease_name}")
    print(f"📁 Image: {image_path.name}")
    print(f"{'='*70}")
    
    with open(image_path, 'rb') as img_file:
        files = {'image': (image_path.name, img_file, 'image/jpeg')}
        
        data = {
            'farmer_id': 'test_farmer_real_data',
            'voice_transcription': f'I think my onion has {disease_name.lower()} disease',
            'weather_context': json.dumps({
                'condition': 'Humid',
                'temperature': 28
            })
        }
        
        try:
            response = requests.post(f"{BASE_URL}/api/crop/analyze", files=files, data=data, timeout=30)
            
            if response.status_code == 200:
                result = response.json()
                print(f"\n✅ Analysis Successful!")
                print(f"Analysis ID: {result.get('analysis_id')}")
                print(f"Model: {result.get('model')}")
                
                # Parse the Gemini response
                gemini_response = result.get('result', '')
                print(f"\n📊 Gemini Diagnosis:")
                print(gemini_response[:500] + "..." if len(gemini_response) > 500 else gemini_response)
                
                return True
            else:
                print(f"\n❌ Error: {response.status_code}")
                print(response.text[:200])
                return False
                
        except Exception as e:
            print(f"\n❌ Request failed: {str(e)}")
            return False

def main():
    print("="*70)
    print("🧪 AgriPulse Real-World Disease Detection Test")
    print("="*70)
    print(f"\nTesting with actual onion disease images from: {DATA_DIR}")
    
    # Check if server is running
    try:
        response = requests.get(f"{BASE_URL}/health", timeout=2)
        if response.status_code != 200:
            print("❌ Server is not healthy!")
            return
    except:
        print("❌ Server is not running! Start it with: ./start_server.sh")
        return
    
    print("✅ Server is running\n")
    
    # Test one image from each disease category
    results = {}
    
    for disease_folder in sorted(DATA_DIR.iterdir()):
        if disease_folder.is_dir():
            disease_name = disease_folder.name
            
            # Get first image from this disease folder
            images = list(disease_folder.glob("*.jpg")) + list(disease_folder.glob("*.jpeg")) + list(disease_folder.glob("*.png"))
            
            if images:
                test_image = images[0]  # Test first image
                success = test_disease_image(disease_name, test_image)
                results[disease_name] = success
    
    # Summary
    print("\n" + "="*70)
    print("📊 Test Summary")
    print("="*70)
    
    for disease, passed in results.items():
        status = "✅ PASSED" if passed else "❌ FAILED"
        print(f"{disease:20s}: {status}")
    
    total = len(results)
    passed = sum(results.values())
    print(f"\nTotal: {passed}/{total} diseases successfully analyzed")
    
    if passed == total:
        print("\n🎉 All disease categories successfully analyzed by Gemini!")
    else:
        print(f"\n⚠️  {total - passed} disease(s) failed analysis")

if __name__ == "__main__":
    main()
