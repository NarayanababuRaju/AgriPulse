from typing import Dict, Any
from loguru import logger
from app.core.config import get_settings
from app.services.weather_providers.base import WeatherProvider
from app.services.weather_providers.openweather import OpenWeatherProvider
from app.services.weather_providers.google_maps import GoogleWeatherProvider

class WeatherService:
    """
    Unified Weather Service Façade.
    Automatically selects the best available provider.
    """

    def __init__(self):
        self.settings = get_settings()
        self.provider: WeatherProvider = None
        
        # Strategy: Prefer Google if available (Example logic), else OpenWeather
        if self.settings.openweather_api_key:
             logger.info("Initializing OpenWeatherMap Provider")
             self.provider = OpenWeatherProvider(self.settings.openweather_api_key)
        else:
            logger.warning("No Weather API Key found. Service will return mocks.")
            self.provider = None

    async def get_current_weather(self, lat: float, lon: float) -> Dict[str, Any]:
        if not self.provider:
            return self._get_mock_weather(lat, lon)
            
        try:
            return await self.provider.get_current_weather(lat, lon)
        except Exception as e:
            logger.error(f"Weather provider failed: {e}")
            return self._get_mock_weather(lat, lon)

    async def get_forecast(self, lat: float, lon: float) -> Dict[str, Any]:
        if not self.provider:
            return self._get_mock_forecast()

        try:
            return await self.provider.get_forecast(lat, lon)
        except Exception as e:
            logger.error(f"Weather forecast failed: {e}")
            return self._get_mock_forecast()

    def _get_mock_weather(self, lat: float, lon: float) -> Dict[str, Any]:
        return {
            "condition": "Clear",
            "description": "clear sky",
            "temperature": 28.5,
            "humidity": 65,
            "wind_speed": 3.5,
            "location": "Mock Location",
            "source": "Mock Data"
        }

    def _get_mock_forecast(self) -> Dict[str, Any]:
        return {
            "daily_summary": [
                 {"time": "Tomorrow", "condition": "Clouds", "temp": 29.0, "rain_chance": 10}
            ],
            "location": "Mock Location",
            "source": "Mock Data"
        }
