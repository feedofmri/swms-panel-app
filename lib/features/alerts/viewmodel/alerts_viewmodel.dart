import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../../core/models/alert.dart';
import '../../../core/models/sensor_data.dart';
import '../../../core/services/websocket_service.dart';
import '../../../core/services/storage_service.dart';
import '../../../core/services/notification_service.dart';
import '../../../core/utils/helpers.dart';
import '../model/alerts_model.dart';

/// ViewModel for the Alerts screen following MVVM pattern
class AlertsViewModel extends ChangeNotifier {
  final WebSocketService _webSocketService;
  final StorageService _storageService;
  final NotificationService _notificationService;

  AlertsModel _model = AlertsModel();
  StreamSubscription<SensorData>? _sensorDataSubscription;
  double _reservoirMinLevel = 20.0;
  double _turbidityMax = 15.0;

  AlertsViewModel({
    required WebSocketService webSocketService,
    required StorageService storageService,
    required NotificationService notificationService,
  }) : _webSocketService = webSocketService,
       _storageService = storageService,
       _notificationService = notificationService {
    _initialize();
  }

  // Getters
  AlertsModel get model => _model;
  List<Alert> get alerts => _model.alerts;
  List<Alert> get unreadAlerts => _model.unreadAlerts;
  int get totalAlerts => _model.totalAlerts;
  int get criticalAlerts => _model.criticalAlerts;
  int get warningAlerts => _model.warningAlerts;
  Alert? get latestAlert => _model.latestAlert;
  bool get hasUnreadCriticalAlerts => _model.hasUnreadCriticalAlerts;
  String get alertSummary => _model.alertSummary;

  /// Initialize the alerts system
  Future<void> _initialize() async {
    await _loadStoredAlerts();
    await _loadSettings();
    _listenToSensorUpdates();
    await _notificationService.initialize();
  }

  /// Load stored alerts from storage
  Future<void> _loadStoredAlerts() async {
    try {
      final storedAlerts = await _storageService.getAlerts();
      // Sort alerts by timestamp (newest first)
      storedAlerts.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      _updateModel(AlertsModel.fromAlerts(storedAlerts));
      debugPrint('AlertsViewModel: Loaded ${storedAlerts.length} stored alerts');
    } catch (e) {
      debugPrint('AlertsViewModel: Failed to load stored alerts: $e');
    }
  }

  /// Load threshold settings
  Future<void> _loadSettings() async {
    try {
      _reservoirMinLevel = await _storageService.getReservoirMinLevel();
      _turbidityMax = await _storageService.getTurbidityMax();
      debugPrint('AlertsViewModel: Loaded settings - reservoir: $_reservoirMinLevel, turbidity: $_turbidityMax');
    } catch (e) {
      debugPrint('AlertsViewModel: Failed to load settings: $e');
    }
  }

  /// Listen to sensor data updates for alert generation
  void _listenToSensorUpdates() {
    _sensorDataSubscription = _webSocketService.sensorDataStream.listen(
      (sensorData) {
        _processSensorDataForAlerts(sensorData);
      },
      onError: (error) {
        debugPrint('AlertsViewModel: Sensor data stream error: $error');
      },
    );
  }

  /// Process sensor data and generate alerts if needed
  Future<void> _processSensorDataForAlerts(SensorData sensorData) async {
    final generatedAlert = AppHelpers.generateAlertFromSensorData(
      sensorData,
      reservoirMinLevel: _reservoirMinLevel,
      turbidityMax: _turbidityMax,
    );

    if (generatedAlert != null) {
      await addAlert(generatedAlert);
    }
  }

  /// Add a new alert
  Future<void> addAlert(Alert alert) async {
    try {
      // Check if similar alert already exists in recent alerts (last 10 minutes)
      final recentAlerts = _model.alerts.where((existingAlert) {
        final timeDiff = DateTime.now().difference(existingAlert.timestamp);
        return timeDiff.inMinutes < 10 &&
               existingAlert.message == alert.message &&
               existingAlert.source == alert.source;
      }).toList();

      if (recentAlerts.isNotEmpty) {
        debugPrint('AlertsViewModel: Similar alert exists, skipping: ${alert.message}');
        return;
      }

      final updatedAlerts = [alert, ..._model.alerts];
      _updateModel(AlertsModel.fromAlerts(updatedAlerts));

      // Save to storage
      await _saveAlerts();

      // Show notification for critical alerts
      if (alert.level == AlertLevel.critical || alert.level == AlertLevel.emergency) {
        await _notificationService.showAlertNotification(alert);
      }

      debugPrint('AlertsViewModel: Added new alert: ${alert.message}');
    } catch (e) {
      debugPrint('AlertsViewModel: Failed to add alert: $e');
    }
  }

  /// Mark alert as read
  Future<void> markAlertAsRead(String alertId) async {
    try {
      final updatedAlerts = _model.alerts.map((alert) {
        if (alert.id == alertId) {
          return alert.copyWith(isRead: true);
        }
        return alert;
      }).toList();

      _updateModel(AlertsModel.fromAlerts(updatedAlerts));
      await _saveAlerts();

      debugPrint('AlertsViewModel: Marked alert as read: $alertId');
    } catch (e) {
      debugPrint('AlertsViewModel: Failed to mark alert as read: $e');
    }
  }

  /// Mark all alerts as read
  Future<void> markAllAlertsAsRead() async {
    try {
      final updatedAlerts = _model.alerts.map((alert) {
        return alert.copyWith(isRead: true);
      }).toList();

      _updateModel(AlertsModel.fromAlerts(updatedAlerts));
      await _saveAlerts();

      debugPrint('AlertsViewModel: Marked all alerts as read');
    } catch (e) {
      debugPrint('AlertsViewModel: Failed to mark all alerts as read: $e');
    }
  }

  /// Delete alert
  Future<void> deleteAlert(String alertId) async {
    try {
      final updatedAlerts = _model.alerts.where((alert) => alert.id != alertId).toList();
      _updateModel(AlertsModel.fromAlerts(updatedAlerts));
      await _saveAlerts();

      debugPrint('AlertsViewModel: Deleted alert: $alertId');
    } catch (e) {
      debugPrint('AlertsViewModel: Failed to delete alert: $e');
    }
  }

  /// Clear all alerts
  Future<void> clearAllAlerts() async {
    try {
      _updateModel(AlertsModel.fromAlerts([]));
      await _storageService.clearAlerts();
      await _notificationService.cancelAllNotifications();

      debugPrint('AlertsViewModel: Cleared all alerts');
    } catch (e) {
      debugPrint('AlertsViewModel: Failed to clear all alerts: $e');
    }
  }

  /// Get alerts filtered by level
  List<Alert> getAlertsByLevel(AlertLevel level) {
    return _model.getAlertsByLevel(level);
  }

  /// Get today's alerts
  List<Alert> getTodayAlerts() {
    return _model.getTodayAlerts();
  }

  /// Refresh alerts
  Future<void> refresh() async {
    await _loadStoredAlerts();
    await _loadSettings();
  }

  /// Save alerts to storage
  Future<void> _saveAlerts() async {
    try {
      await _storageService.saveAlerts(_model.alerts);
    } catch (e) {
      debugPrint('AlertsViewModel: Failed to save alerts: $e');
    }
  }

  /// Update model and notify listeners
  void _updateModel(AlertsModel newModel) {
    _model = newModel;
    notifyListeners();
  }

  /// Create manual alert (for testing or manual entry)
  Future<void> createManualAlert({
    required String message,
    required AlertLevel level,
    String? source,
  }) async {
    final alert = Alert(
      id: Alert.generateId(),
      message: message,
      level: level,
      source: source ?? 'manual',
    );

    await addAlert(alert);
  }

  @override
  void dispose() {
    _sensorDataSubscription?.cancel();
    super.dispose();
  }
}
