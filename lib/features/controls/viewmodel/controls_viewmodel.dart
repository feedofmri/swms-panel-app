import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../../core/services/websocket_service.dart';
import '../../../core/models/sensor_data.dart';

class ControlsViewModel extends ChangeNotifier {
  final WebSocketService _webSocketService;

  StreamSubscription<SensorData>? _sensorDataSubscription;
  SensorData? _currentSensorData;
  bool _pump1IsLoading = false;
  bool _pump2IsLoading = false;
  String? _lastCommandStatus;

  ControlsViewModel({
    required WebSocketService webSocketService,
  }) : _webSocketService = webSocketService {
    _initializeListeners();
  }

  // Basic getters
  SensorData? get currentSensorData => _currentSensorData;
  SensorData? get model => _currentSensorData;
  bool get isConnected => _webSocketService.isConnected;
  String get connectionStatus => _webSocketService.connectionStatus;
  bool get pump1IsLoading => _pump1IsLoading;
  bool get pump2IsLoading => _pump2IsLoading;
  String? get lastCommandStatus => _lastCommandStatus;
  String? get lastCommandResult => _lastCommandStatus;

  // UI-expected getters
  bool get canSendCommands => _webSocketService.isConnected;
  String get pump1Status => _currentSensorData?.pump1Status ?? 'OFF';
  String get pump2Status => _currentSensorData?.pump2Status ?? 'OFF';
  int get runningPumpsCount =>
      (pump1Status == 'ON' ? 1 : 0) + (pump2Status == 'ON' ? 1 : 0);
  bool get isAnyPumpRunning => pump1Status == 'ON' || pump2Status == 'ON';
  String get statusSummary {
    if (!isConnected) return 'Disconnected';
    if (isAnyPumpRunning) return '$runningPumpsCount pump(s) running';
    return 'All pumps stopped';
  }

  void _initializeListeners() {
    _sensorDataSubscription = _webSocketService.sensorDataStream.listen(
      (sensorData) {
        _currentSensorData = sensorData;
        notifyListeners();
      },
    );
  }

  Future<bool> controlPump1(bool turnOn) async {
    if (!_webSocketService.isConnected) {
      _lastCommandStatus = 'Not connected to ESP8266';
      notifyListeners();
      return false;
    }

    _pump1IsLoading = true;
    _lastCommandStatus = null;
    notifyListeners();

    try {
      final success = await _webSocketService.controlPump('pump1', turnOn);
      if (success) {
        _lastCommandStatus = 'Pump 1 ${turnOn ? 'started' : 'stopped'} successfully';
      } else {
        _lastCommandStatus = 'Failed to control Pump 1';
      }
      return success;
    } catch (e) {
      _lastCommandStatus = 'Error controlling Pump 1: $e';
      return false;
    } finally {
      _pump1IsLoading = false;
      notifyListeners();
    }
  }

  Future<bool> controlPump2(bool turnOn) async {
    if (!_webSocketService.isConnected) {
      _lastCommandStatus = 'Not connected to ESP8266';
      notifyListeners();
      return false;
    }

    _pump2IsLoading = true;
    _lastCommandStatus = null;
    notifyListeners();

    try {
      final success = await _webSocketService.controlPump('pump2', turnOn);
      if (success) {
        _lastCommandStatus = 'Pump 2 ${turnOn ? 'started' : 'stopped'} successfully';
      } else {
        _lastCommandStatus = 'Failed to control Pump 2';
      }
      return success;
    } catch (e) {
      _lastCommandStatus = 'Error controlling Pump 2: $e';
      return false;
    } finally {
      _pump2IsLoading = false;
      notifyListeners();
    }
  }

  // Methods expected by the UI
  Future<void> togglePump1() async {
    final currentlyOn = pump1Status == 'ON';
    await controlPump1(!currentlyOn);
  }

  Future<void> togglePump2() async {
    final currentlyOn = pump2Status == 'ON';
    await controlPump2(!currentlyOn);
  }

  Future<void> emergencyStopAllPumps() async {
    _lastCommandStatus = 'Emergency stop initiated...';
    notifyListeners();

    try {
      final results = await Future.wait([
        controlPump1(false),
        controlPump2(false),
      ]);

      if (results.every((result) => result)) {
        _lastCommandStatus = 'Emergency stop completed - All pumps stopped';
      } else {
        _lastCommandStatus = 'Emergency stop partially failed';
      }
    } catch (e) {
      _lastCommandStatus = 'Emergency stop failed: $e';
    }
  }

  Future<bool> silenceBuzzer() async {
    if (!_webSocketService.isConnected) {
      _lastCommandStatus = 'Not connected to ESP8266';
      notifyListeners();
      return false;
    }

    try {
      final success = await _webSocketService.silenceBuzzer();
      if (success) {
        _lastCommandStatus = 'Buzzer silenced successfully';
      } else {
        _lastCommandStatus = 'Failed to silence buzzer';
      }
      return success;
    } catch (e) {
      _lastCommandStatus = 'Error silencing buzzer: $e';
      return false;
    } finally {
      notifyListeners();
    }
  }

  void clearStatus() {
    _lastCommandStatus = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _sensorDataSubscription?.cancel();
    super.dispose();
  }
}
