
import asyncio
import os
from pprint import pprint
from dotenv import load_dotenv

# Load environment variables from .env file
load_dotenv(os.path.join(os.path.dirname(__file__), "../.env"))

from app.services.weather_service import WeatherService

async def test_weather_service():
    print("🧪 Testing Weather Service")
    print("=" * 60)
    
    # Check if API key is set
    # Using environment variable check directly since we aren't loading .env here
    api_key = os.getenv("OPENWEATHER_API_KEY")
    if api_key:
        print(f"✅ Found OPENWEATHER_API_KEY: {api_key[:5]}...")
    else:
        print("⚠️ OPENWEATHER_API_KEY not found in environment. Expecting MOCK data.")
    
    service = WeatherService()
    
    # Test Location: Bangalore (12.9716, 77.5946)
    lat, lon = 12.9716, 77.5946
    
    # 1. Test Current Weather
    print("\n1️⃣ Getting Current Weather for Bangalore...")
    try:
        weather = await service.get_current_weather(lat, lon)
        pprint(weather)
        
        if "is_mock" in weather:
            print("Types: [MOCK DATA RETURNED]")
        else:
            print("Types: [LIVE API DATA RETURNED]")
            
    except Exception as e:
        print(f"❌ Failed: {e}")
        
    # 2. Test Forecast
    print("\n2️⃣ Getting 5-Day Forecast for Bangalore...")
    try:
        forecast = await service.get_forecast(lat, lon)
        print(f"Location: {forecast.get('location')}")
        print(f"Forecast entries: {len(forecast.get('daily_summary', []))}")
        
        if forecast.get("daily_summary"):
            print("Next forecast item:")
            pprint(forecast["daily_summary"][0])
            
        if "is_mock" in forecast:
            print("Types: [MOCK DATA RETURNED]")
        else:
            print("Types: [LIVE API DATA RETURNED]")
            
    except Exception as e:
        print(f"❌ Failed: {e}")

if __name__ == "__main__":
    asyncio.run(test_weather_service())
