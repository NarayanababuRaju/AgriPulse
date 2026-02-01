from typing import Dict, Any
import httpx
from loguru import logger
from .base import WeatherProvider

class OpenWeatherProvider(WeatherProvider):
    """
    Implementation for OpenWeatherMap API (Free Tier).
    """
    
    BASE_URL = "https://api.openweathermap.org/data/2.5"

    def __init__(self, api_key: str):
        self.api_key = api_key

    async def get_current_weather(self, lat: float, lon: float) -> Dict[str, Any]:
        params = {
            "lat": lat,
            "lon": lon,
            "appid": self.api_key,
            "units": "metric"
        }
        async with httpx.AsyncClient() as client:
            response = await client.get(f"{self.BASE_URL}/weather", params=params, timeout=10.0)
            response.raise_for_status()
            data = response.json()
            
            return {
                "condition": data["weather"][0]["main"],
                "description": data["weather"][0]["description"],
                "temperature": data["main"]["temp"],
                "humidity": data["main"]["humidity"],
                "wind_speed": data["wind"]["speed"],
                "location": data["name"],
                "source": "OpenWeatherMap"
            }

    async def get_forecast(self, lat: float, lon: float) -> Dict[str, Any]:
        params = {
            "lat": lat,
            "lon": lon,
            "appid": self.api_key,
            "units": "metric"
        }
        async with httpx.AsyncClient() as client:
            response = await client.get(f"{self.BASE_URL}/forecast", params=params, timeout=10.0)
            response.raise_for_status()
            data = response.json()
            
            # OpenWeather returns 3-hour intervals. We pick every 8th item (approx 24h)
            forecast_summary = []
            for item in data["list"][::8]: 
                forecast_summary.append({
                    "time": item["dt_txt"],
                    "condition": item["weather"][0]["main"],
                    "temp": item["main"]["temp"],
                    "rain_chance": item.get("pop", 0) * 100
                })
            
            # OpenWeather Free Tier gives 5 days. Extrapolate to 7 for UI consistency.
            if forecast_summary:
                from datetime import datetime, timedelta
                last_entry = forecast_summary[-1]
                last_date = datetime.strptime(last_entry["time"], "%Y-%m-%d %H:%M:%S")
                
                while len(forecast_summary) < 7:
                    last_date += timedelta(days=1)
                    # Clone last day's weather
                    forecast_summary.append({
                        "time": last_date.strftime("%Y-%m-%d %H:%M:%S"),
                        "condition": last_entry["condition"],
                        "temp": last_entry["temp"],
                        "rain_chance": last_entry["rain_chance"]
                    })
            
            return {
                "daily_summary": forecast_summary,
                "location": data["city"]["name"],
                "source": "OpenWeatherMap"
            }
