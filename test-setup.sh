#!/bin/bash

echo "🧪 Testing DJI Cloud API Demo Setup..."
echo "====================================="

# Function to check if a service is responding
check_service() {
    local url=$1
    local name=$2
    local max_attempts=30
    local attempt=1
    
    echo "🔍 Checking $name..."
    while [ $attempt -le $max_attempts ]; do
        if curl -s -f "$url" > /dev/null 2>&1; then
            echo "✅ $name is responding"
            return 0
        fi
        echo "⏳ Attempt $attempt/$max_attempts - waiting for $name..."
        sleep 2
        ((attempt++))
    done
    echo "❌ $name failed to respond after $max_attempts attempts"
    return 1
}

# Start services
echo "🚀 Starting services..."
docker-compose up -d

# Wait a bit for services to initialize
echo "⏳ Waiting for services to initialize..."
sleep 10

# Check each service
echo ""
echo "🔍 Service Health Checks:"
echo "========================"

# Check MySQL (using docker exec since MySQL doesn't have HTTP interface)
if docker exec cloud_api_sample_mysql mysqladmin ping -h localhost -u root -proot > /dev/null 2>&1; then
    echo "✅ MySQL is responding"
else
    echo "❌ MySQL is not responding"
fi

# Check Redis  
if docker exec cloud_api_sample_redis redis-cli ping > /dev/null 2>&1; then
    echo "✅ Redis is responding"
else
    echo "❌ Redis is not responding"
fi

# Check MediaMTX API Server (not web interface, as it may not have one)
check_service "http://localhost:9997" "MediaMTX API Server"

# Check DJI Cloud API
check_service "http://localhost:6789/actuator/health" "DJI Cloud API Health"

# Check API endpoints
check_service "http://localhost:6789/swagger-ui/index.html" "Swagger UI"

echo ""
echo "📋 Service URLs:"
echo "================"
echo "🌐 DJI Cloud API: http://localhost:6789"
echo "📖 Swagger UI: http://localhost:6789/swagger-ui/index.html"
echo "❤️ Health Check: http://localhost:6789/actuator/health"
echo "📹 MediaMTX Web UI: http://localhost:8888"
echo "📡 RTSP Stream: rtsp://admin:admin123@localhost:8554/live/dji"

echo ""
echo "🎥 Test RTSP Stream:"
echo "==================="
echo "VLC: vlc rtsp://admin:admin123@localhost:8554/live/dji"
echo "FFplay: ffplay rtsp://admin:admin123@localhost:8554/live/dji"

echo ""
echo "🛑 To stop all services: docker-compose down" 