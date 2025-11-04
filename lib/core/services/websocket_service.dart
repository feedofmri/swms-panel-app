import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/status.dart' as status;
import '../models/sensor_data.dart';
import '../models/esp_serial_data.dart';
import 'data_smoothing_service.dart';

/// Service for managing WebSocket connection to ESP8266
class WebSocketService extends ChangeNotifier {
  WebSocketChannel? _channel;
  StreamSubscription? _subscription;
  Timer? _reconnectTimer;
  Timer? _heartbeatTimer;

  String? _espIpAddress;
  bool _isConnected = false;
  bool _isConnecting = false;
  String _connectionStatus = 'Disconnected';
  int _reconnectAttempts = 0;
  static const int maxReconnectAttempts = 5;
  static const Duration reconnectDelay = Duration(seconds: 3);
  static const Duration heartbeatInterval = Duration(seconds: 30);

  // Stream controller for incoming sensor data
  final StreamController<SensorData> _sensorDataController =
      StreamController<SensorData>.broadcast();

  final StreamController<String> _rawMessageController =
      StreamController<String>.broadcast();

  // New stream controller for ESP serial data
  final StreamController<EspSerialData> _espSerialDataController =
      StreamController<EspSerialData>.broadcast();

  // Cumulative sensor data storage
  Map<String, dynamic> _cumulativeSensorData = {};
  Timer? _sensorDataTimer;
  static const Duration sensorDataTimeout = Duration(seconds: 2);

  // Data smoothing service for filtering sensor dropouts
  final DataSmoothingService _dataSmoothingService = DataSmoothingService();

  // Getters
  bool get isConnected => _isConnected;
  bool get isConnecting => _isConnecting;
  String get connectionStatus => _connectionStatus;
  String? get espIpAddress => _espIpAddress;
  Stream<SensorData> get sensorDataStream => _sensorDataController.stream;
  Stream<String> get rawMessageStream => _rawMessageController.stream;
  Stream<EspSerialData> get espSerialDataStream => _espSerialDataController.stream;

  /// Connect to ESP8266 WebSocket server
  Future<void> connect(String ipAddress) async {
    if (_isConnecting || _isConnected) {
      debugPrint('WebSocket: Already connecting or connected');
      return;
    }

    _espIpAddress = ipAddress;
    _isConnecting = true;
    _connectionStatus = 'Connecting...';

    // Reset data smoothing service for fresh start
    _dataSmoothingService.reset();

    notifyListeners();

    try {
      debugPrint('WebSocket: Attempting to connect to ws://$ipAddress:81');

      final uri = Uri.parse('ws://$ipAddress:81');
      _channel = WebSocketChannel.connect(uri);

      // Wait for connection to be established
      await _channel!.ready;

      _isConnected = true;
      _isConnecting = false;
      _connectionStatus = 'Connected';
      _reconnectAttempts = 0;

      debugPrint('WebSocket: Connected successfully to $ipAddress');

      // Start listening to messages
      _startListening();

      // Start heartbeat
      _startHeartbeat();

      notifyListeners();
    } catch (e) {
      debugPrint('WebSocket: Connection failed: $e');
      _isConnected = false;
      _isConnecting = false;
      _connectionStatus = 'Connection Failed';
      notifyListeners();

      // Attempt to reconnect
      _scheduleReconnect();
    }
  }

  /// Start listening to WebSocket messages
  void _startListening() {
    _subscription = _channel!.stream.listen(
      (data) {
        _handleIncomingMessage(data.toString());
      },
      onError: (error) {
        debugPrint('WebSocket: Listen error: $error');
        _handleConnectionLost();
      },
      onDone: () {
        debugPrint('WebSocket: Connection closed');
        _handleConnectionLost();
      },
    );
  }

  /// Handle incoming WebSocket messages
  void _handleIncomingMessage(String message) {
    try {
      debugPrint('WebSocket: Received raw message: $message');

      // Add to raw message stream
      _rawMessageController.add(message);

      // Try to parse as JSON first (for structured sensor data)
      try {
        final jsonData = json.decode(message.trim());
        if (jsonData is Map<String, dynamic>) {
          final rawSensorData = SensorData.fromJson(jsonData);
          // Apply data smoothing to filter dropouts
          final smoothedSensorData = _dataSmoothingService.processSensorData(rawSensorData);
          _sensorDataController.add(smoothedSensorData);
          debugPrint('WebSocket: Parsed and smoothed sensor data: $smoothedSensorData');
          return;
        } else if (jsonData is List) {
          // Handle list of sensor data
          for (var item in jsonData) {
            if (item is Map<String, dynamic>) {
              final rawSensorData = SensorData.fromJson(item);
              // Apply data smoothing to filter dropouts
              final smoothedSensorData = _dataSmoothingService.processSensorData(rawSensorData);
              _sensorDataController.add(smoothedSensorData);
              debugPrint('WebSocket: Parsed and smoothed sensor data: $smoothedSensorData');
            }
          }
          return;
        }
      } catch (jsonError) {
        // Not JSON, treat as raw ESP8266 serial data
        debugPrint('WebSocket: Message is not JSON, treating as ESP serial data');
      }

      // Handle raw ESP8266 serial data with cumulative approach
      final espSerialData = EspSerialData.fromRawMessage(message.trim());
      _espSerialDataController.add(espSerialData);

      // Accumulate sensor data from individual ESP messages
      if (espSerialData.parsedData != null) {
        _accumulateSensorData(espSerialData.parsedData!);
      }

      debugPrint('WebSocket: Parsed ESP serial data: $espSerialData');

    } catch (e) {
      debugPrint('WebSocket: Failed to parse message: $e');
      debugPrint('WebSocket: Raw message was: $message');
    }
  }

  /// Accumulate sensor data from individual ESP messages and build complete SensorData
  void _accumulateSensorData(Map<String, dynamic> newData) {
    // Update cumulative data with new values
    _cumulativeSensorData.addAll(newData);

    // Reset/restart the timer
    _sensorDataTimer?.cancel();
    _sensorDataTimer = Timer(sensorDataTimeout, () {
      _buildAndEmitSensorData();
    });

    // If we detect a sensor cycle reset (e.g., "=== Sensor Readings ==="), emit immediately
    if (newData.keys.any((key) => key.contains('sensor') && key.contains('readings'))) {
      _sensorDataTimer?.cancel();
      _buildAndEmitSensorData();
    }
  }

  /// Build complete SensorData from accumulated values and emit it
  void _buildAndEmitSensorData() {
    if (_cumulativeSensorData.isEmpty) return;

    try {
      // Map accumulated data to SensorData fields
      final mappedData = <String, dynamic>{};

      for (final entry in _cumulativeSensorData.entries) {
        final key = entry.key.toLowerCase();
        final value = entry.value;

        // Map various possible field names to standard ones
        if (key.contains('reservoir') || key.contains('tank1') || key == 'reservoir_level') {
          mappedData['reservoir_level'] = value;
        } else if (key.contains('house') || key.contains('tank2') || key == 'house_tank_level') {
          mappedData['house_tank_level'] = value;
        } else if (key.contains('optional') || key.contains('tank3') || key == 'optional_tank') {
          mappedData['optional_tank_level'] = value;
        } else if (key.contains('filter') || key.contains('yl_69') || key == 'yl_69_filter') {
          mappedData['filter_tank'] = value;
        } else if (key.contains('turbidity') || key.contains('clarity')) {
          mappedData['turbidity'] = value;
        } else if (key.contains('pump') && key.contains('1') || key == 'pump_1') {
          mappedData['pump1'] = value;
        } else if (key.contains('pump') && key.contains('2') || key == 'pump_2') {
          mappedData['pump2'] = value;
        } else if (key.contains('pump') && key.contains('3') || key == 'pump_3') {
          mappedData['pump3'] = value;
        } else if (key.contains('battery') || key.contains('power')) {
          mappedData['battery'] = value;
        } else if (key.contains('alert') || key.contains('warning')) {
          mappedData['alert'] = value;
        }
      }

      // Create raw SensorData with accumulated values
      final rawSensorData = SensorData.fromJson({
        'reservoir_level': mappedData['reservoir_level'] ?? 0,
        'house_tank_level': mappedData['house_tank_level'] ?? 0,
        'optional_tank_level': mappedData['optional_tank_level'] ?? 0,
        'filter_tank': mappedData['filter_tank'] ?? 'unknown',
        'turbidity': mappedData['turbidity'] ?? 0,
        'pump1': mappedData['pump1'] ?? 'OFF',
        'pump2': mappedData['pump2'] ?? 'OFF',
        'pump3': mappedData['pump3'] ?? 'OFF',
        'battery': mappedData['battery'] ?? 0,
        'alert': mappedData['alert'],
      });

      // Apply data smoothing to filter dropouts
      final smoothedSensorData = _dataSmoothingService.processSensorData(rawSensorData);
      _sensorDataController.add(smoothedSensorData);
      debugPrint('WebSocket: Built and smoothed complete SensorData from accumulated ESP data: $smoothedSensorData');

      // Keep the data for next cycle (don't clear completely, just update timestamps)
      // This way we maintain the last known state of all sensors

    } catch (e) {
      debugPrint('WebSocket: Failed to build SensorData from accumulated data: $e');
    }
  }

  /// Handle connection lost
  void _handleConnectionLost() {
    _isConnected = false;
    _connectionStatus = 'Disconnected';
    _stopHeartbeat();
    notifyListeners();

    // Attempt to reconnect if we have an IP address
    if (_espIpAddress != null) {
      _scheduleReconnect();
    }
  }

  /// Schedule a reconnection attempt
  void _scheduleReconnect() {
    if (_reconnectAttempts >= maxReconnectAttempts) {
      debugPrint('WebSocket: Max reconnect attempts reached');
      _connectionStatus = 'Connection Failed - Max Attempts Reached';
      notifyListeners();
      return;
    }

    _reconnectAttempts++;
    _connectionStatus = 'Reconnecting... (${_reconnectAttempts}/$maxReconnectAttempts)';
    notifyListeners();

    _reconnectTimer = Timer(reconnectDelay, () {
      if (_espIpAddress != null) {
        connect(_espIpAddress!);
      }
    });
  }

  /// Start heartbeat to keep connection alive
  void _startHeartbeat() {
    _heartbeatTimer = Timer.periodic(heartbeatInterval, (timer) {
      if (_isConnected) {
        sendCommand({'type': 'heartbeat'});
      }
    });
  }

  /// Stop heartbeat timer
  void _stopHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = null;
  }

  /// Send command to ESP8266
  Future<bool> sendCommand(Map<String, dynamic> command) async {
    if (!_isConnected || _channel == null) {
      debugPrint('WebSocket: Cannot send command - not connected');
      return false;
    }

    try {
      final commandJson = json.encode(command);
      _channel!.sink.add(commandJson);
      debugPrint('WebSocket: Sent command: $commandJson');
      return true;
    } catch (e) {
      debugPrint('WebSocket: Failed to send command: $e');
      return false;
    }
  }

  /// Send pump control command
  Future<bool> controlPump(String pumpId, bool turnOn) async {
    return sendCommand({
      'command': 'pump_control',
      'pump': pumpId,
      'action': turnOn ? 'ON' : 'OFF',
    });
  }

  /// Send buzzer silence command
  Future<bool> silenceBuzzer() async {
    return sendCommand({
      'command': 'buzzer_off',
    });
  }

  /// Disconnect from WebSocket
  void disconnect() {
    debugPrint('WebSocket: Disconnecting...');

    _stopHeartbeat();
    _reconnectTimer?.cancel();
    _subscription?.cancel();

    _channel?.sink.close(status.goingAway);
    _channel = null;

    _isConnected = false;
    _isConnecting = false;
    _connectionStatus = 'Disconnected';
    _reconnectAttempts = 0;

    notifyListeners();
  }

  /// Reset connection and retry
  void resetConnection() {
    disconnect();
    if (_espIpAddress != null) {
      Timer(const Duration(seconds: 1), () {
        connect(_espIpAddress!);
      });
    }
  }

  @override
  void dispose() {
    disconnect();
    _sensorDataController.close();
    _rawMessageController.close();
    _espSerialDataController.close();
    super.dispose();
  }
}
