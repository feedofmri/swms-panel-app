import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../../core/models/pump_status.dart';
import '../../../core/models/sensor_data.dart';
import '../../../core/services/websocket_service.dart';
import '../model/controls_model.dart';

/// ViewModel for the Controls screen following MVVM pattern
class ControlsViewModel extends ChangeNotifier {
  final WebSocketService _webSocketService;

  ControlsModel _model = ControlsModel(
    pump1Status: PumpStatus(pumpId: 'pump1', isOn: false),
    pump2Status: PumpStatus(pumpId: 'pump2', isOn: false),
  );

  StreamSubscription<SensorData>? _sensorDataSubscription;

  ControlsViewModel({
    required WebSocketService webSocketService,
  }) : _webSocketService = webSocketService {
    _initialize();
  }

  // Getters
  ControlsModel get model => _model;
  bool get isConnected => _model.isConnected;
  bool get canSendCommands => _model.canSendCommands;
  PumpStatus get pump1Status => _model.pump1Status;
  PumpStatus get pump2Status => _model.pump2Status;
  bool get isBuzzerActive => _model.isBuzzerActive;
  bool get isAnyPumpRunning => _model.isAnyPumpRunning;
  bool get areBothPumpsRunning => _model.areBothPumpsRunning;
  int get runningPumpsCount => _model.runningPumpsCount;
  String get statusSummary => _model.statusSummary;
  String? get lastCommandResult => _model.lastCommandResult;

  /// Initialize the controls
  void _initialize() {
    _listenToWebSocketUpdates();
    _listenToConnectionChanges();
  }

  /// Listen to WebSocket sensor data updates
  void _listenToWebSocketUpdates() {
    _sensorDataSubscription = _webSocketService.sensorDataStream.listen(
      (sensorData) {
        _updatePumpStatusFromSensorData(sensorData);
      },
      onError: (error) {
        debugPrint('ControlsViewModel: Sensor data stream error: $error');
      },
    );
  }

  /// Listen to WebSocket connection changes
  void _listenToConnectionChanges() {
    _webSocketService.addListener(_onConnectionStatusChanged);
  }

  /// Handle WebSocket connection status changes
  void _onConnectionStatusChanged() {
    _updateModel(isConnected: _webSocketService.isConnected);
  }

  /// Update pump status from sensor data
  void _updatePumpStatusFromSensorData(SensorData sensorData) {
    final pump1On = sensorData.pump1Status.toUpperCase() == 'ON';
    final pump2On = sensorData.pump2Status.toUpperCase() == 'ON';

    final newPump1Status = pump1On != _model.pump1Status.isOn
        ? _model.pump1Status.copyWith(isOn: pump1On, lastToggled: DateTime.now())
        : _model.pump1Status;

    final newPump2Status = pump2On != _model.pump2Status.isOn
        ? _model.pump2Status.copyWith(isOn: pump2On, lastToggled: DateTime.now())
        : _model.pump2Status;

    _updateModel(
      pump1Status: newPump1Status,
      pump2Status: newPump2Status,
    );

    debugPrint('ControlsViewModel: Updated pump status - P1: $pump1On, P2: $pump2On');
  }

  /// Toggle pump 1
  Future<bool> togglePump1() async {
    if (!canSendCommands) {
      debugPrint('ControlsViewModel: Cannot send command - not ready');
      return false;
    }

    final newState = !_model.pump1Status.isOn;
    debugPrint('ControlsViewModel: Toggling Pump 1 to ${newState ? 'ON' : 'OFF'}');

    _updateModel(
      lastCommandSent: DateTime.now(),
      lastCommandResult: null,
    );

    try {
      final success = await _webSocketService.controlPump('pump1', newState);

      if (success) {
        _updateModel(
          lastCommandResult: 'Pump 1 command sent successfully',
        );
        debugPrint('ControlsViewModel: Pump 1 command sent successfully');
        return true;
      } else {
        _updateModel(
          lastCommandResult: 'Failed to send Pump 1 command',
        );
        debugPrint('ControlsViewModel: Failed to send Pump 1 command');
        return false;
      }
    } catch (e) {
      _updateModel(
        lastCommandResult: 'Error sending Pump 1 command: $e',
      );
      debugPrint('ControlsViewModel: Error sending Pump 1 command: $e');
      return false;
    }
  }

  /// Toggle pump 2
  Future<bool> togglePump2() async {
    if (!canSendCommands) {
      debugPrint('ControlsViewModel: Cannot send command - not ready');
      return false;
    }

    final newState = !_model.pump2Status.isOn;
    debugPrint('ControlsViewModel: Toggling Pump 2 to ${newState ? 'ON' : 'OFF'}');

    _updateModel(
      lastCommandSent: DateTime.now(),
      lastCommandResult: null,
    );

    try {
      final success = await _webSocketService.controlPump('pump2', newState);

      if (success) {
        _updateModel(
          lastCommandResult: 'Pump 2 command sent successfully',
        );
        debugPrint('ControlsViewModel: Pump 2 command sent successfully');
        return true;
      } else {
        _updateModel(
          lastCommandResult: 'Failed to send Pump 2 command',
        );
        debugPrint('ControlsViewModel: Failed to send Pump 2 command');
        return false;
      }
    } catch (e) {
      _updateModel(
        lastCommandResult: 'Error sending Pump 2 command: $e',
      );
      debugPrint('ControlsViewModel: Error sending Pump 2 command: $e');
      return false;
    }
  }

  /// Silence buzzer
  Future<bool> silenceBuzzer() async {
    if (!canSendCommands) {
      debugPrint('ControlsViewModel: Cannot send command - not ready');
      return false;
    }

    debugPrint('ControlsViewModel: Silencing buzzer');

    _updateModel(
      lastCommandSent: DateTime.now(),
      lastCommandResult: null,
    );

    try {
      final success = await _webSocketService.silenceBuzzer();

      if (success) {
        _updateModel(
          isBuzzerActive: false,
          lastCommandResult: 'Buzzer silenced successfully',
        );
        debugPrint('ControlsViewModel: Buzzer silenced successfully');
        return true;
      } else {
        _updateModel(
          lastCommandResult: 'Failed to silence buzzer',
        );
        debugPrint('ControlsViewModel: Failed to silence buzzer');
        return false;
      }
    } catch (e) {
      _updateModel(
        lastCommandResult: 'Error silencing buzzer: $e',
      );
      debugPrint('ControlsViewModel: Error silencing buzzer: $e');
      return false;
    }
  }

  /// Stop all pumps (emergency stop)
  Future<bool> emergencyStopAllPumps() async {
    if (!canSendCommands) {
      debugPrint('ControlsViewModel: Cannot send command - not ready');
      return false;
    }

    debugPrint('ControlsViewModel: Emergency stop - turning off all pumps');

    _updateModel(
      lastCommandSent: DateTime.now(),
      lastCommandResult: null,
    );

    try {
      // Send stop commands to both pumps
      final pump1Success = await _webSocketService.controlPump('pump1', false);
      final pump2Success = await _webSocketService.controlPump('pump2', false);

      if (pump1Success && pump2Success) {
        _updateModel(
          lastCommandResult: 'Emergency stop completed - all pumps stopped',
        );
        debugPrint('ControlsViewModel: Emergency stop completed successfully');
        return true;
      } else {
        _updateModel(
          lastCommandResult: 'Emergency stop partially failed',
        );
        debugPrint('ControlsViewModel: Emergency stop partially failed');
        return false;
      }
    } catch (e) {
      _updateModel(
        lastCommandResult: 'Error during emergency stop: $e',
      );
      debugPrint('ControlsViewModel: Error during emergency stop: $e');
      return false;
    }
  }

  /// Send custom command
  Future<bool> sendCustomCommand(Map<String, dynamic> command) async {
    if (!canSendCommands) {
      debugPrint('ControlsViewModel: Cannot send command - not ready');
      return false;
    }

    debugPrint('ControlsViewModel: Sending custom command: $command');

    _updateModel(
      lastCommandSent: DateTime.now(),
      lastCommandResult: null,
    );

    try {
      final success = await _webSocketService.sendCommand(command);

      if (success) {
        _updateModel(
          lastCommandResult: 'Custom command sent successfully',
        );
        debugPrint('ControlsViewModel: Custom command sent successfully');
        return true;
      } else {
        _updateModel(
          lastCommandResult: 'Failed to send custom command',
        );
        debugPrint('ControlsViewModel: Failed to send custom command');
        return false;
      }
    } catch (e) {
      _updateModel(
        lastCommandResult: 'Error sending custom command: $e',
      );
      debugPrint('ControlsViewModel: Error sending custom command: $e');
      return false;
    }
  }

  /// Update the model and notify listeners
  void _updateModel({
    PumpStatus? pump1Status,
    PumpStatus? pump2Status,
    bool? isConnected,
    bool? isBuzzerActive,
    DateTime? lastCommandSent,
    String? lastCommandResult,
  }) {
    _model = _model.copyWith(
      pump1Status: pump1Status,
      pump2Status: pump2Status,
      isConnected: isConnected,
      isBuzzerActive: isBuzzerActive,
      lastCommandSent: lastCommandSent,
      lastCommandResult: lastCommandResult,
    );
    notifyListeners();
  }

  @override
  void dispose() {
    _sensorDataSubscription?.cancel();
    _webSocketService.removeListener(_onConnectionStatusChanged);
    super.dispose();
  }
}
