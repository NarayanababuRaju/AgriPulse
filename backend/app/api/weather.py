from fastapi import APIRouter, Query, HTTPException
from app.services.weather_service import WeatherService
from typing import Dict, Any

router = APIRouter(prefix="/api/weather", tags=["Weather"])
weather_service = WeatherService()

@router.get("/current", response_model=Dict[str, Any])
async def get_current_weather(
    lat: float = Query(..., description="Latitude"),
    lon: float = Query(..., description="Longitude")
):
    """
    Get current weather for a specific location.
    Acts as a Context Provider for AI analysis.
    """
    try:
        return await weather_service.get_current_weather(lat, lon)
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@router.get("/forecast", response_model=Dict[str, Any])
async def get_forecast(
    lat: float = Query(..., description="Latitude"),
    lon: float = Query(..., description="Longitude")
):
    """
    Get 5-day weather forecast.
    Required for yield prediction and disease forecasting.
    """
    try:
        return await weather_service.get_forecast(lat, lon)
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))
