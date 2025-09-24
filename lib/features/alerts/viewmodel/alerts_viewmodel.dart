import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../../core/services/websocket_service.dart';
import '../../../core/services/storage_service.dart';
import '../../../core/services/notification_service.dart';
import '../../../core/models/sensor_data.dart';

class AlertsViewModel extends ChangeNotifier {
  final WebSocketService _webSocketService;
  final StorageService _storageService;
  final NotificationService _notificationService;

  StreamSubscription<SensorData>? _sensorDataSubscription;
  List<AlertData> _alerts = [];
  SensorData? _currentSensorData;

  AlertsViewModel({
    required WebSocketService webSocketService,
    required StorageService storageService,
    required NotificationService notificationService,
  }) : _webSocketService = webSocketService,
       _storageService = storageService,
       _notificationService = notificationService {
    _initializeListeners();
  }

  List<AlertData> get alerts => _alerts;
  SensorData? get currentSensorData => _currentSensorData;
  bool get isConnected => _webSocketService.isConnected;

  // Additional getters expected by the UI
  int get unreadAlerts => _alerts.where((alert) => !alert.isAcknowledged).length;
  int get totalAlerts => _alerts.length;
  int get criticalAlerts => _alerts.where((alert) => alert.severity == AlertSeverity.critical).length;
  int get warningAlerts => _alerts.where((alert) => alert.severity == AlertSeverity.warning).length;
  AlertData? get latestAlert => _alerts.isNotEmpty ? _alerts.first : null;

  void _initializeListeners() {
    _sensorDataSubscription = _webSocketService.sensorDataStream.listen(
      (sensorData) {
        _currentSensorData = sensorData;
        _checkForAlerts(sensorData);
        notifyListeners();
      },
    );
  }

  void _checkForAlerts(SensorData sensorData) {
    final now = DateTime.now();

    // Check for low water levels
    if (sensorData.reservoirLevel < 20) {
      _addAlert(AlertData(
        id: 'reservoir_low',
        title: 'Low Reservoir Level',
        message: 'Reservoir water level is critically low (${sensorData.reservoirLevel.toStringAsFixed(1)}%)',
        severity: AlertSeverity.critical,
        timestamp: now,
      ));
    }

    if (sensorData.houseTankLevel < 15) {
      _addAlert(AlertData(
        id: 'house_tank_low',
        title: 'Low House Tank Level',
        message: 'House tank water level is critically low (${sensorData.houseTankLevel.toStringAsFixed(1)}%)',
        severity: AlertSeverity.critical,
        timestamp: now,
      ));
    }

    // Check for high turbidity
    if (sensorData.turbidity > 10) {
      _addAlert(AlertData(
        id: 'high_turbidity',
        title: 'High Water Turbidity',
        message: 'Water turbidity is above acceptable levels (${sensorData.turbidity.toStringAsFixed(1)} NTU)',
        severity: AlertSeverity.warning,
        timestamp: now,
      ));
    }

    // Check for low battery
    if (sensorData.battery < 20) {
      _addAlert(AlertData(
        id: 'low_battery',
        title: 'Low Battery',
        message: 'System battery is low (${sensorData.battery.toStringAsFixed(1)}%)',
        severity: AlertSeverity.warning,
        timestamp: now,
      ));
    }
  }

  void _addAlert(AlertData alert) {
    // Remove existing alert with same ID
    _alerts.removeWhere((a) => a.id == alert.id);

    // Add new alert
    _alerts.insert(0, alert);

    // Limit to 50 alerts
    if (_alerts.length > 50) {
      _alerts = _alerts.take(50).toList();
    }

    // Send notification for critical alerts
    if (alert.severity == AlertSeverity.critical) {
      _notificationService.showNotification(alert.title, alert.message);
    }
  }

  // Methods expected by the UI
  Future<void> refresh() async {
    // Refresh connection status and trigger UI update
    notifyListeners();
  }

  void markAlertAsRead(String alertId) {
    final alertIndex = _alerts.indexWhere((alert) => alert.id == alertId);
    if (alertIndex != -1) {
      _alerts[alertIndex] = _alerts[alertIndex].copyWith(isAcknowledged: true);
      notifyListeners();
    }
  }

  void markAllAlertsAsRead() {
    _alerts = _alerts.map((alert) => alert.copyWith(isAcknowledged: true)).toList();
    notifyListeners();
  }

  void deleteAlert(String alertId) {
    _alerts.removeWhere((alert) => alert.id == alertId);
    notifyListeners();
  }

  List<AlertData> getAlertsByLevel(AlertSeverity severity) {
    return _alerts.where((alert) => alert.severity == severity).toList();
  }

  void dismissAlert(String alertId) {
    deleteAlert(alertId);
  }

  void clearAllAlerts() {
    _alerts.clear();
    notifyListeners();
  }

  @override
  void dispose() {
    _sensorDataSubscription?.cancel();
    super.dispose();
  }
}

// Update AlertData class to match UI expectations
class AlertData {
  final String id;
  final String title;
  final String message;
  final AlertSeverity severity;
  final DateTime timestamp;
  final bool isAcknowledged;

  AlertData({
    required this.id,
    required this.title,
    required this.message,
    required this.severity,
    required this.timestamp,
    this.isAcknowledged = false,
  });

  AlertData copyWith({
    String? id,
    String? title,
    String? message,
    AlertSeverity? severity,
    DateTime? timestamp,
    bool? isAcknowledged,
  }) {
    return AlertData(
      id: id ?? this.id,
      title: title ?? this.title,
      message: message ?? this.message,
      severity: severity ?? this.severity,
      timestamp: timestamp ?? this.timestamp,
      isAcknowledged: isAcknowledged ?? this.isAcknowledged,
    );
  }
}

enum AlertSeverity {
  info,
  warning,
  critical,
}

// Add Alert typedef for backwards compatibility with existing UI
typedef Alert = AlertData;
