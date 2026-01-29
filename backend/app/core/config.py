from pydantic_settings import BaseSettings
from functools import lru_cache
from typing import Optional


class Settings(BaseSettings):
    # API Keys
    gemini_api_key: str
    weather_api_key: Optional[str] = None
    openweather_api_key: Optional[str] = None
    google_maps_weather_api_key: Optional[str] = None
    
    # GCP Configuration
    gcp_project_id: str
    gcp_location: str = "asia-south1"
    google_application_credentials: str
    
    # Storage
    gcs_bucket_name: str
    firestore_database_id: str = "agri-pulse-firestore-db"
    
    # Firebase
    firebase_project_id: str
    
    # Server
    port: int = 8080
    log_level: str = "info"
    debug: bool = True
    
    class Config:
        env_file = ".env"
        case_sensitive = False


@lru_cache()
def get_settings() -> Settings:
    return Settings()
