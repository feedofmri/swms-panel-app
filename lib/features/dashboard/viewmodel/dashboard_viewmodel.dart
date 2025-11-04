import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../../core/services/websocket_service.dart';
import '../../../core/services/storage_service.dart';
import '../../../core/models/sensor_data.dart';
import '../model/dashboard_model.dart';

class DashboardViewModel extends ChangeNotifier {
  final WebSocketService _webSocketService;
  final StorageService _storageService;

  DashboardModel _dashboardModel = DashboardModel();
  StreamSubscription<SensorData>? _sensorDataSubscription;
  StreamSubscription<String>? _rawDataSubscription;

  DashboardViewModel({
    required WebSocketService webSocketService,
    required StorageService storageService,
  }) : _webSocketService = webSocketService,
       _storageService = storageService {
    _initializeListeners();
  }

  // Dashboard model and connection status
  DashboardModel get dashboardModel => _dashboardModel;
  DashboardModel get model => _dashboardModel;
  bool get isConnected => _webSocketService.isConnected;
  String get connectionStatus => _webSocketService.connectionStatus;

  // Sensor data getters that the UI expects
  double get reservoirPercentage => _dashboardModel.currentData?.reservoirLevel ?? 0.0;
  double get houseTankPercentage => _dashboardModel.currentData?.houseTankLevel ?? 0.0;
  double get optionalTankPercentage => _dashboardModel.currentData?.optionalTankLevel ?? 0.0;
  bool get isTurbidityGood => (_dashboardModel.currentData?.turbidity ?? 0.0) < 5.0;
  double get turbidityValue => _dashboardModel.currentData?.turbidity ?? 0.0;
  double get batteryVoltage => _dashboardModel.currentData?.battery ?? 0.0;
  String get filterTankStatus => _dashboardModel.currentData?.filterTank ?? 'unknown';
  bool get isPump1On => (_dashboardModel.currentData?.pump1Status ?? 'OFF').toUpperCase() == 'ON';
  bool get isPump2On => (_dashboardModel.currentData?.pump2Status ?? 'OFF').toUpperCase() == 'ON';
  bool get isPump3On => (_dashboardModel.currentData?.pump3Status ?? 'OFF').toUpperCase() == 'ON';
  String? get currentAlert => _dashboardModel.currentData?.alert;
  String get systemStatus => _getSystemStatus();

  String _getSystemStatus() {
    if (!isConnected) return 'Disconnected';
    if (_dashboardModel.currentData == null) return 'No Data';
    if (currentAlert != null) return 'Alert: $currentAlert';
    if (isPump1On || isPump2On || isPump3On) return 'Active';
    return 'Normal';
  }

  String getDataFreshness() {
    if (_dashboardModel.lastUpdate == null) return 'Never';
    final diff = DateTime.now().difference(_dashboardModel.lastUpdate!);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }

  void _initializeListeners() {
    // Listen to structured sensor data
    _sensorDataSubscription = _webSocketService.sensorDataStream.listen(
      (sensorData) {
        _updateDashboard(sensorData);
      },
    );

    // Listen to raw ESP data and try to convert it to sensor data
    _rawDataSubscription = _webSocketService.rawMessageStream.listen(
      (rawMessage) {
        _handleRawMessage(rawMessage);
      },
    );
  }

  void _updateDashboard(SensorData sensorData) {
    _dashboardModel = _dashboardModel.copyWith(
      currentData: sensorData,
      isDataAvailable: true,
      lastUpdate: DateTime.now(),
      isConnected: _webSocketService.isConnected,
      connectionStatus: _webSocketService.connectionStatus,
    );
    notifyListeners();
  }

  void _handleRawMessage(String rawMessage) {
    // Try to parse raw ESP message into sensor data
    final sensorData = _parseEspMessageToSensorData(rawMessage);
    if (sensorData != null) {
      _updateDashboard(sensorData);
    }
  }

  SensorData? _parseEspMessageToSensorData(String message) {
    try {
      // Handle common ESP8266 serial output formats
      final trimmed = message.trim();

      // Example parsing for different formats your ESP might send
      // Format 1: "Tank1:75,Tank2:60,Pump1:ON,Pump2:OFF,Battery:85"
      if (trimmed.contains(':') && trimmed.contains(',')) {
        final data = <String, dynamic>{};
        final parts = trimmed.split(',');

        for (final part in parts) {
          final keyValue = part.split(':');
          if (keyValue.length == 2) {
            final key = keyValue[0].trim().toLowerCase();
            final value = keyValue[1].trim();

            switch (key) {
              case 'tank1':
              case 'reservoir':
                data['reservoir_level'] = double.tryParse(value) ?? 0;
                break;
              case 'tank2':
              case 'house':
                data['house_tank_level'] = double.tryParse(value) ?? 0;
                break;
              case 'tank3':
              case 'optional':
                data['optional_tank_level'] = double.tryParse(value) ?? 0;
                break;
              case 'pump1':
                data['pump1'] = value.toUpperCase();
                break;
              case 'pump2':
                data['pump2'] = value.toUpperCase();
                break;
              case 'pump3':
                data['pump3'] = value.toUpperCase();
                break;
              case 'battery':
                data['battery'] = double.tryParse(value) ?? 0;
                break;
              case 'turbidity':
                data['turbidity'] = double.tryParse(value) ?? 0;
                break;
              case 'filter':
                data['filter_tank'] = value;
                break;
            }
          }
        }

        if (data.isNotEmpty) {
          return SensorData.fromJson({
            'reservoir_level': data['reservoir_level'] ?? 0,
            'house_tank_level': data['house_tank_level'] ?? 0,
            'optional_tank_level': data['optional_tank_level'] ?? 0,
            'filter_tank': data['filter_tank'] ?? 'unknown',
            'turbidity': data['turbidity'] ?? 0,
            'pump1': data['pump1'] ?? 'OFF',
            'pump2': data['pump2'] ?? 'OFF',
            'pump3': data['pump3'] ?? 'OFF',
            'battery': data['battery'] ?? 0,
          });
        }
      }

      // Format 2: Multi-line format
      // "Reservoir Level: 75%\nHouse Tank: 60%\nPump 1: ON"
      final lines = trimmed.split('\n');
      final data = <String, dynamic>{
        'reservoir_level': 0.0,
        'house_tank_level': 0.0,
        'optional_tank_level': 0.0,
        'filter_tank': 'unknown',
        'turbidity': 0.0,
        'pump1': 'OFF',
        'pump2': 'OFF',
        'pump3': 'OFF',
        'battery': 0.0,
      };

      for (final line in lines) {
        if (line.contains(':')) {
          final parts = line.split(':');
          if (parts.length >= 2) {
            final key = parts[0].trim().toLowerCase();
            final valueStr = parts[1].trim().replaceAll('%', '').replaceAll('L', '');

            if (key.contains('reservoir') || key.contains('tank 1')) {
              data['reservoir_level'] = double.tryParse(valueStr) ?? 0;
            } else if (key.contains('house') || key.contains('tank 2')) {
              data['house_tank_level'] = double.tryParse(valueStr) ?? 0;
            } else if (key.contains('optional') || key.contains('tank 3')) {
              data['optional_tank_level'] = double.tryParse(valueStr) ?? 0;
            } else if (key.contains('pump 1') || key.contains('pump1')) {
              data['pump1'] = valueStr.toUpperCase();
            } else if (key.contains('pump 2') || key.contains('pump2')) {
              data['pump2'] = valueStr.toUpperCase();
            } else if (key.contains('pump 3') || key.contains('pump3')) {
              data['pump3'] = valueStr.toUpperCase();
            } else if (key.contains('battery')) {
              data['battery'] = double.tryParse(valueStr) ?? 0;
            } else if (key.contains('turbidity')) {
              data['turbidity'] = double.tryParse(valueStr) ?? 0;
            } else if (key.contains('filter')) {
              data['filter_tank'] = valueStr;
            }
          }
        }
      }

      return SensorData.fromJson(data);

    } catch (e) {
      debugPrint('Failed to parse ESP message to sensor data: $e');
      return null;
    }
  }

  Future<void> refresh() async {
    // Update connection status
    _dashboardModel = _dashboardModel.copyWith(
      isConnected: _webSocketService.isConnected,
      connectionStatus: _webSocketService.connectionStatus,
    );
    notifyListeners();
  }

  @override
  void dispose() {
    _sensorDataSubscription?.cancel();
    _rawDataSubscription?.cancel();
    super.dispose();
  }
}
