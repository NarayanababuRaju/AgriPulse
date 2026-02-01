from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from loguru import logger
import sys

# Configure logging
logger.remove()
logger.add(sys.stdout, level="INFO", format="<green>{time:YYYY-MM-DD HH:mm:ss}</green> | <level>{level: <8}</level> | <cyan>{name}</cyan>:<cyan>{function}</cyan> - <level>{message}</level>")

app = FastAPI(
    title="AgriPulse API",
    description="Backend API for AgriPulse - Agricultural Advisory Platform powered by Gemini 3",
    version="0.1.0"
)

# Configure CORS for Flutter Web
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # Adjust in production
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Import routers
from app.api import crop, feedback, weather, speech, utils

# Include routers
app.include_router(crop.router)
app.include_router(feedback.router)
app.include_router(weather.router)
app.include_router(speech.router)
app.include_router(utils.router)

@app.on_event("startup")
async def startup_event():
    logger.info("AgriPulse API starting up...")

@app.on_event("shutdown")
async def shutdown_event():
    logger.info("AgriPulse API shutting down...")

@app.get("/")
async def root():
    return {
        "message": "Welcome to AgriPulse API",
        "status": "online",
        "version": "0.1.0",
        "docs": "/docs"
    }

@app.get("/health")
async def health_check():
    return {"status": "healthy"}
