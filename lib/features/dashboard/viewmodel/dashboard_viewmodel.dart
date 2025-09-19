import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../../core/models/sensor_data.dart';
import '../../../core/services/websocket_service.dart';
import '../../../core/services/storage_service.dart';
import '../model/dashboard_model.dart';

/// ViewModel for the Dashboard screen following MVVM pattern
class DashboardViewModel extends ChangeNotifier {
  final WebSocketService _webSocketService;
  final StorageService _storageService;

  DashboardModel _model = DashboardModel();
  StreamSubscription<SensorData>? _sensorDataSubscription;
  Timer? _dataFreshnessTimer;

  DashboardViewModel({
    required WebSocketService webSocketService,
    required StorageService storageService,
  }) : _webSocketService = webSocketService,
       _storageService = storageService {
    _initialize();
  }

  // Getters
  DashboardModel get model => _model;
  SensorData? get currentData => _model.currentData;
  bool get isConnected => _model.isConnected;
  bool get isDataAvailable => _model.isDataAvailable;
  String get connectionStatus => _model.connectionStatus;
  SystemStatus get systemStatus => _model.systemStatus;

  /// Initialize the dashboard
  Future<void> _initialize() async {
    await _loadStoredData();
    _listenToWebSocketUpdates();
    _listenToConnectionChanges();
    _startDataFreshnessTimer();
  }

  /// Load stored sensor data
  Future<void> _loadStoredData() async {
    try {
      final lastSensorData = await _storageService.getLastSensorData();
      if (lastSensorData != null) {
        _updateModel(
          currentData: lastSensorData,
          isDataAvailable: true,
          lastUpdate: lastSensorData.timestamp,
        );
        debugPrint('DashboardViewModel: Loaded stored sensor data');
      }
    } catch (e) {
      debugPrint('DashboardViewModel: Failed to load stored data: $e');
    }
  }

  /// Listen to WebSocket sensor data updates
  void _listenToWebSocketUpdates() {
    _sensorDataSubscription = _webSocketService.sensorDataStream.listen(
      (sensorData) {
        _handleSensorDataUpdate(sensorData);
      },
      onError: (error) {
        debugPrint('DashboardViewModel: Sensor data stream error: $error');
      },
    );
  }

  /// Listen to WebSocket connection changes
  void _listenToConnectionChanges() {
    _webSocketService.addListener(_onConnectionStatusChanged);
  }

  /// Handle WebSocket connection status changes
  void _onConnectionStatusChanged() {
    _updateModel(
      isConnected: _webSocketService.isConnected,
      connectionStatus: _webSocketService.connectionStatus,
    );
  }

  /// Handle new sensor data
  Future<void> _handleSensorDataUpdate(SensorData sensorData) async {
    _updateModel(
      currentData: sensorData,
      isDataAvailable: true,
      lastUpdate: DateTime.now(),
    );

    // Store the latest data
    try {
      await _storageService.saveLastSensorData(sensorData);
    } catch (e) {
      debugPrint('DashboardViewModel: Failed to save sensor data: $e');
    }

    debugPrint('DashboardViewModel: Updated with new sensor data: $sensorData');
  }

  /// Update the model and notify listeners
  void _updateModel({
    SensorData? currentData,
    bool? isDataAvailable,
    DateTime? lastUpdate,
    bool? isConnected,
    String? connectionStatus,
  }) {
    _model = _model.copyWith(
      currentData: currentData,
      isDataAvailable: isDataAvailable,
      lastUpdate: lastUpdate,
      isConnected: isConnected,
      connectionStatus: connectionStatus,
    );
    notifyListeners();
  }

  /// Start timer to check data freshness
  void _startDataFreshnessTimer() {
    _dataFreshnessTimer = Timer.periodic(
      const Duration(seconds: 10),
      (timer) {
        // Trigger UI update to refresh data freshness indicators
        notifyListeners();
      },
    );
  }

  /// Refresh dashboard data
  Future<void> refresh() async {
    debugPrint('DashboardViewModel: Refreshing dashboard data');

    // Try to reconnect if disconnected
    if (!_webSocketService.isConnected) {
      final espIp = await _storageService.getEspIpAddress();
      if (espIp != null) {
        await _webSocketService.connect(espIp);
      }
    }

    // Reload stored data
    await _loadStoredData();
  }

  /// Get data freshness indicator
  String getDataFreshness() {
    if (_model.lastUpdate == null) return 'No Data';

    final now = DateTime.now();
    final difference = now.difference(_model.lastUpdate!);

    if (difference.inSeconds < 10) return 'Live';
    if (difference.inSeconds < 30) return 'Recent';
    if (difference.inMinutes < 5) return 'Stale';
    return 'Old';
  }

  /// Get reservoir level percentage
  double get reservoirPercentage {
    return _model.currentData?.reservoirLevel ?? 0.0;
  }

  /// Get house tank level percentage
  double get houseTankPercentage {
    return _model.currentData?.houseTankLevel ?? 0.0;
  }

  /// Get turbidity value
  double get turbidityValue {
    return _model.currentData?.turbidity ?? 0.0;
  }

  /// Get battery voltage
  double get batteryVoltage {
    return _model.currentData?.battery ?? 0.0;
  }

  /// Get pump 1 status
  bool get isPump1On {
    return _model.currentData?.pump1Status.toUpperCase() == 'ON';
  }

  /// Get pump 2 status
  bool get isPump2On {
    return _model.currentData?.pump2Status.toUpperCase() == 'ON';
  }

  /// Get filter tank status
  String get filterTankStatus {
    return _model.currentData?.filterTank ?? 'unknown';
  }

  /// Get current alert message
  String? get currentAlert {
    return _model.currentData?.alert;
  }

  /// Check if turbidity is good
  bool get isTurbidityGood {
    return _model.currentData?.isTurbidityGood ?? false;
  }

  /// Check if any pump is running
  bool get isAnyPumpRunning {
    return _model.currentData?.isAnyPumpRunning ?? false;
  }

  @override
  void dispose() {
    _sensorDataSubscription?.cancel();
    _dataFreshnessTimer?.cancel();
    _webSocketService.removeListener(_onConnectionStatusChanged);
    super.dispose();
  }
}
