#!/bin/bash
# AgriPulse Backend Startup Script

echo "🚀 Starting AgriPulse Backend Server..."
echo "=================================="

# Check if .env file exists
if [ ! -f ".env" ]; then
    echo "❌ Error: .env file not found!"
    echo "Please create .env file from .env.example"
    exit 1
fi

# Check if service account exists
if [ ! -f "config/service-account.json" ]; then
    echo "⚠️  Warning: service-account.json not found in config/"
    echo "Some features may not work without GCP credentials"
fi

echo "✅ Configuration files found"
echo "Starting server on http://localhost:8080"
echo "Swagger docs will be available at http://localhost:8080/docs"
echo ""

# Start uvicorn
uvicorn app.main:app --host 127.0.0.1 --port 8080 --reload
