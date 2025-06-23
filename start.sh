#!/bin/bash

echo "🚀 Starting DJI Cloud API Demo Environment..."
echo "=============================================="

# Step 1: Build the application
echo "📦 Building the application..."
./build.sh

if [ $? -ne 0 ]; then
    echo "❌ Build failed! Exiting."
    exit 1
fi

# Step 2: Stop any existing containers
echo "🛑 Stopping existing containers..."
docker-compose down

# Step 3: Start the services
echo "🐳 Starting Docker services..."
docker-compose up --build

echo "✅ DJI Cloud API Demo started successfully!"
echo ""
echo "📋 Service URLs:"
echo "   - DJI Cloud API: http://localhost:6789"
echo "   - Swagger UI: http://localhost:6789/swagger-ui/index.html"
echo "   - RTSP Stream: rtsp://admin:admin123@localhost:8554/live/dji"
echo "   - MediaMTX Web UI: http://localhost:8888"
echo "   - Health Check: http://localhost:6789/actuator/health"
echo ""
echo "🎥 RTSP Stream URLs:"
echo "   - Main stream: rtsp://admin:admin123@localhost:8554/live/dji"
echo "   - Test with VLC: vlc rtsp://admin:admin123@localhost:8554/live/dji"
echo ""
echo "To stop: docker-compose down" 