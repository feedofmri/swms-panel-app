# ESP8266 Integration Guide

## Overview
Your Flutter SWMS Panel app now includes ESP8266 serial data monitoring capabilities. The app can connect to your ESP8266 via WebSocket and display live serial data from your device.

## How It Works

### ESP8266 Side
Your ESP8266 code creates:
- A WebSocket server on port 81 (`ws://<ESP_IP>:81/`)
- A web interface on port 80 (`http://<ESP_IP>/`)
- Streams all serial data through WebSocket in real-time

### Flutter App Side
The app now includes:
- **ESP Monitor Screen**: A new tab in your bottom navigation
- **WebSocket Service**: Enhanced to handle both JSON sensor data and raw text messages
- **Real-time Display**: Live streaming of all ESP8266 serial output
- **Message Categorization**: Automatically categorizes messages (sensor readings, errors, status, etc.)

## Using the ESP Monitor

### 1. Connect to Your ESP8266
1. Open your Flutter app
2. Navigate to the **ESP Monitor** tab (rightmost tab with monitor icon)
3. Enter your ESP8266's IP address (default: 192.168.1.114)
4. Tap **Connect**

### 2. View Live Data
- All serial output from your ESP8266 will appear in real-time
- Messages are color-coded by type:
  - 🔴 **Red**: Error messages
  - 🟢 **Green**: Status updates
  - 🔵 **Blue**: Sensor readings
  - 🟠 **Orange**: Control actions
  - ⚪ **Gray**: General messages

### 3. Controls Available
- **Pause/Resume**: Stop/start message streaming
- **Clear**: Clear all messages from the display
- **Auto-scroll**: Automatically scroll to newest messages
- **Disconnect**: Close WebSocket connection

## Features

### Message Analysis
- **Numeric Detection**: Automatically highlights numeric values in messages
- **Timestamp**: Each message shows when it was received
- **Message Types**: Categorizes messages based on content
- **Memory Management**: Keeps only the last 1000 messages to prevent memory issues

### Connection Management
- **Auto-reconnect**: Automatically attempts to reconnect if connection is lost
- **Connection Status**: Visual indicator shows connection state
- **Error Handling**: Graceful handling of connection failures

## ESP8266 Setup Instructions

### 1. Update WiFi Credentials
In your ESP8266 code, replace:
```cpp
const char* SSID = "REPLACE_ME";
const char* PASS = "REPLACE_ME";
```

### 2. Upload and Run
1. Upload the code to your ESP8266
2. Open Serial Monitor to see the IP address
3. Use that IP in your Flutter app

### 3. Test Connection
1. Open `http://<ESP_IP>/` in a web browser to see the built-in web interface
2. Connect from your Flutter app to see the same data

## Integration with Existing Features

The ESP Monitor works alongside your existing SWMS features:
- **Dashboard**: Still shows structured sensor data if sent as JSON
- **Alerts**: Can trigger alerts based on ESP messages
- **Controls**: Can send commands to ESP (if implemented on ESP side)
- **Settings**: Stores ESP IP address for auto-connection

## Troubleshooting

### Connection Issues
- Ensure ESP8266 and phone are on the same WiFi network
- Check that ESP8266 is powered and running
- Verify the IP address is correct
- Try the web interface first: `http://<ESP_IP>/`

### No Messages Appearing
- Check if ESP8266 is sending data to Serial
- Verify WebSocket server is running on ESP8266
- Check Flutter app logs for connection errors

### App Performance
- Use Pause feature if too many messages are flooding the display
- Clear messages periodically to free memory
- Disable auto-scroll for better performance with high message rates

## Next Steps

You can enhance this integration by:
1. **Adding Commands**: Implement command sending from Flutter to ESP8266
2. **Data Parsing**: Parse specific sensor data formats for dashboard integration
3. **Filtering**: Add message filtering options
4. **Export**: Add ability to export/save message logs
5. **Notifications**: Trigger notifications based on specific ESP messages

The foundation is now in place for full bidirectional communication between your Flutter app and ESP8266!
