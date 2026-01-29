from abc import ABC, abstractmethod
from typing import Dict, Any

class WeatherProvider(ABC):
    """
    Abstract Base Class for Weather Providers.
    Any new weather service (Google, AccuWeather) must implement this contract.
    """
    
    @abstractmethod
    async def get_current_weather(self, lat: float, lon: float) -> Dict[str, Any]:
        """Return standardized current weather"""
        pass

    @abstractmethod
    async def get_forecast(self, lat: float, lon: float) -> Dict[str, Any]:
        """Return standardized 7-day forecast"""
        pass
