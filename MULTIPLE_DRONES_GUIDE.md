# Multiple Drones & Livestreaming Guide

## Overview

The DJI Cloud API Demo supports **multiple drones simultaneously**, each with their own unique livestream URLs. The single RTSP URL in the configuration is just a **base template** - the system dynamically creates unique URLs for each drone.

## How Multiple Drone Streams Work

### 1. **Drone Identification**
Each drone is uniquely identified by:
- **Serial Number (SN)**: Unique identifier like `1ZNDH360010162`
- **Camera Position**: Payload index like `39-0-7` (camera type and position)
- **Video Type**: `normal`, `infrared`, etc.

### 2. **Dynamic URL Generation**
The system creates unique URLs for each drone using this pattern:

**Base Configuration:**
```yaml
rtsp:
  host: localhost
  port: 8554
  username: admin
  password: admin123
  stream-path: /live/dji  # This is just the base template
```

**Generated URLs for Multiple Drones:**
```
rtsp://admin:admin123@localhost:8554/live/DRONE001-39-0-7
rtsp://admin:admin123@localhost:8554/live/DRONE002-39-0-7
rtsp://admin:admin123@localhost:8554/live/DRONE003-52-0-0
```

### 3. **VideoId Format**
Each stream is identified by a `VideoId` in this format:
```
{drone_serial_number}/{camera_position}/{video_type}-{index}
```

Examples:
- `1ZNDH360010162/39-0-7/normal-0` - Main camera on drone
- `1ZNDH360010162/52-0-0/infrared-0` - Infrared camera
- `1ZNDH360010162/50-0-1/normal-0` - Secondary camera

## Supported Stream Types

### **RTSP Streams (Recommended)**
- **Multiple Drones**: Each gets unique path
- **Example URLs**:
  ```
  rtsp://admin:admin123@localhost:8554/live/DRONE001-39-0-7
  rtsp://admin:admin123@localhost:8554/live/DRONE002-39-0-7
  rtsp://admin:admin123@localhost:8554/live/DRONE003-52-0-0
  ```

### **RTMP Streams**
- **Base URL**: `rtmp://localhost:1935/live/`
- **Per-Drone**: `rtmp://localhost:1935/live/DRONE001-39-0-7`

### **WebRTC (WHIP)**
- **Base URL**: `http://localhost:1985/rtc/v1/whip/?app=live&stream=`
- **Per-Drone**: `http://localhost:1985/rtc/v1/whip/?app=live&stream=DRONE001-39-0-7`

### **Agora RTC**
- Each drone gets its own channel with SN embedded
- Requires Agora token generation per drone

## API Endpoints for Multiple Drones

### **Get Live Capacity**
```http
GET /manage/api/v1/live/capacity
```
Returns all available drones and their camera capabilities:
```json
{
  "code": 0,
  "data": [
    {
      "sn": "DRONE001",
      "name": "Drone Alpha",
      "camerasList": [
        {
          "payloadIndex": "39-0-7",
          "availableVideoNumber": 1,
          "coexistVideoNumberMax": 1
        }
      ]
    },
    {
      "sn": "DRONE002", 
      "name": "Drone Beta",
      "camerasList": [...]
    }
  ]
}
```

### **Start Livestream for Specific Drone**
```http
POST /manage/api/v1/live/streams/start
Content-Type: application/json

{
  "videoId": "DRONE001/39-0-7/normal-0",
  "urlType": "RTSP",
  "videoQuality": "ADAPTIVE"
}
```

### **Stop Livestream for Specific Drone**
```http
POST /manage/api/v1/live/streams/stop
Content-Type: application/json

{
  "videoId": "DRONE001/39-0-7/normal-0"
}
```

## Camera Position Codes

Common camera position codes you'll see:
- `39-0-7`: Main camera (typical for most DJI drones)
- `52-0-0`: Infrared/Thermal camera
- `50-0-1`: Secondary/Zoom camera
- `42-0-0`: FPV camera

## Testing Multiple Drone Streams

### **Using VLC Media Player**
```bash
# Drone 1
vlc rtsp://admin:admin123@localhost:8554/live/DRONE001-39-0-7

# Drone 2  
vlc rtsp://admin:admin123@localhost:8554/live/DRONE002-39-0-7

# Drone 3
vlc rtsp://admin:admin123@localhost:8554/live/DRONE003-52-0-0
```

### **Using FFplay**
```bash
# Open multiple streams simultaneously
ffplay rtsp://admin:admin123@localhost:8554/live/DRONE001-39-0-7 &
ffplay rtsp://admin:admin123@localhost:8554/live/DRONE002-39-0-7 &
ffplay rtsp://admin:admin123@localhost:8554/live/DRONE003-52-0-0 &
```

### **Web-based Viewing**
Access MediaMTX web interface at `http://localhost:8888` to see all active streams.

## Scaling Considerations

### **MediaMTX Configuration**
The MediaMTX server supports regex patterns for dynamic path matching:
```yaml
paths:
  # Supports any drone stream pattern
  "~^live/[A-Z0-9]+-.*":
    # Automatically handles: live/DRONE001-39-0-7, live/DRONE002-52-0-0, etc.
```

### **Resource Usage**
- **CPU**: Each stream uses ~10-15% CPU per HD stream
- **Memory**: ~50-100MB per active stream
- **Network**: ~2-5 Mbps per HD stream
- **Concurrent Streams**: Limited by server resources

### **Load Balancing**
For high-scale deployments:
- Use multiple MediaMTX instances
- Implement stream routing based on drone SN
- Consider CDN integration for global distribution

## Troubleshooting

### **Stream Not Appearing**
1. Check if drone is online: `GET /manage/api/v1/live/capacity`
2. Verify VideoId format: `{sn}/{camera}/{type}-{index}`
3. Check MediaMTX logs: `docker logs dji_mediamtx`

### **Multiple Drones, Same Stream Path**
The system automatically prevents conflicts by including the drone SN in the path.

### **Camera Not Available**
Some drones have multiple cameras - check the capacity endpoint to see available cameras per drone.

## Example: Managing 3 Drones

```javascript
// JavaScript example for managing multiple drone streams
const drones = [
  { sn: 'DRONE001', camera: '39-0-7' },
  { sn: 'DRONE002', camera: '39-0-7' },
  { sn: 'DRONE003', camera: '52-0-0' }
];

// Start all streams
drones.forEach(drone => {
  fetch('/manage/api/v1/live/streams/start', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({
      videoId: `${drone.sn}/${drone.camera}/normal-0`,
      urlType: 'RTSP',
      videoQuality: 'ADAPTIVE'
    })
  });
});

// Generate RTSP URLs for viewing
const rtspUrls = drones.map(drone => 
  `rtsp://admin:admin123@localhost:8554/live/${drone.sn}-${drone.camera}`
);
```

This architecture allows you to manage dozens of drones simultaneously, each with their own unique livestream URLs! 