import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../../core/services/websocket_service.dart';
import '../../../core/services/storage_service.dart';
import '../model/settings_model.dart';

class SettingsViewModel extends ChangeNotifier {
  final WebSocketService _webSocketService;
  final StorageService _storageService;

  SettingsModel _settings = SettingsModel();
  bool _isLoading = false;

  SettingsViewModel({
    required WebSocketService webSocketService,
    required StorageService storageService,
  }) : _webSocketService = webSocketService,
       _storageService = storageService {
    _loadSettings();
  }

  // Basic getters
  SettingsModel get settings => _settings;
  bool get isLoading => _isLoading;
  bool get isConnected => _webSocketService.isConnected;
  String get connectionStatus => _webSocketService.connectionStatus;
  String? get currentEspIp => _webSocketService.espIpAddress;

  // UI-expected getters
  String get espIpAddress => _settings.espIpAddress;
  bool get hasUnsavedChanges => _settings.hasUnsavedChanges;
  bool get isValid => _settings.isValid;
  List<String> get validationErrors => _settings.validationErrors;
  String? get lastSavedTimestamp => _settings.lastSavedTimestamp;
  double get reservoirMinLevel => _settings.reservoirMinLevel;
  double get turbidityMax => _settings.turbidityMax;

  // Threshold getters for UI widgets
  double get lowWaterThreshold => _settings.lowWaterThreshold;
  double get highTurbidityThreshold => _settings.highTurbidityThreshold;
  double get lowBatteryThreshold => _settings.lowBatteryThreshold;
  bool get alertsEnabled => _settings.alertsEnabled;
  bool get soundEnabled => _settings.soundEnabled;
  bool get vibrationEnabled => _settings.vibrationEnabled;

  // Callback getters for UI widgets (return functions that update settings)
  Function(double) get updateReservoirMinLevel => (double value) {
    _settings = _settings.copyWith(
      reservoirMinLevel: value,
      hasUnsavedChanges: true,
    );
    notifyListeners();
  };

  Function(double) get updateTurbidityMax => (double value) {
    _settings = _settings.copyWith(
      turbidityMax: value,
      hasUnsavedChanges: true,
    );
    notifyListeners();
  };

  void discardChanges() {
    _settings = _settings.copyWith(hasUnsavedChanges: false);
    _loadSettings(); // Reload from storage
  }

  String getSettingsSummary() {
    return 'ESP: ${_settings.espIpAddress.isEmpty ? 'Not configured' : _settings.espIpAddress}\n'
           'Reservoir Min: ${_settings.reservoirMinLevel}%\n'
           'Turbidity Max: ${_settings.turbidityMax}\n'
           'Alerts: ${_settings.alertsEnabled ? 'Enabled' : 'Disabled'}';
  }

  Future<void> _loadSettings() async {
    _isLoading = true;
    notifyListeners();

    try {
      final espIp = await _storageService.getEspIpAddress();
      final thresholds = await _storageService.getThresholds();
      final alertSettings = await _storageService.getAlertSettings();

      _settings = _settings.copyWith(
        espIpAddress: espIp ?? '',
        lowWaterThreshold: thresholds?['lowWater'] ?? 20.0,
        highTurbidityThreshold: thresholds?['highTurbidity'] ?? 10.0,
        lowBatteryThreshold: thresholds?['lowBattery'] ?? 20.0,
        alertsEnabled: alertSettings?['enabled'] ?? true,
        soundEnabled: alertSettings?['sound'] ?? true,
        vibrationEnabled: alertSettings?['vibration'] ?? true,
        hasUnsavedChanges: false,
      );
    } catch (e) {
      debugPrint('Error loading settings: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  bool validateIpAddress(String ipAddress) {
    final ipRegex = RegExp(r'^(?:(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.){3}(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)$');
    return ipRegex.hasMatch(ipAddress);
  }

  Future<bool> updateEspIpAddress(String ipAddress) async {
    try {
      await _storageService.saveEspIpAddress(ipAddress);
      _settings = _settings.copyWith(
        espIpAddress: ipAddress,
        hasUnsavedChanges: false,
        lastSavedTimestamp: DateTime.now().toIso8601String(),
      );
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error saving ESP IP address: $e');
      return false;
    }
  }

  Future<bool> updateThresholds({
    double? lowWaterThreshold,
    double? highTurbidityThreshold,
    double? lowBatteryThreshold,
  }) async {
    try {
      final thresholds = <String, double>{
        'lowWater': lowWaterThreshold ?? _settings.lowWaterThreshold,
        'highTurbidity': highTurbidityThreshold ?? _settings.highTurbidityThreshold,
        'lowBattery': lowBatteryThreshold ?? _settings.lowBatteryThreshold,
      };

      await _storageService.saveThresholds(thresholds);

      _settings = _settings.copyWith(
        lowWaterThreshold: thresholds['lowWater'],
        highTurbidityThreshold: thresholds['highTurbidity'],
        lowBatteryThreshold: thresholds['lowBattery'],
        hasUnsavedChanges: false,
        lastSavedTimestamp: DateTime.now().toIso8601String(),
      );

      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error saving thresholds: $e');
      return false;
    }
  }

  Future<bool> updateAlertSettings({
    bool? alertsEnabled,
    bool? soundEnabled,
    bool? vibrationEnabled,
  }) async {
    try {
      final alertSettings = <String, bool>{
        'enabled': alertsEnabled ?? _settings.alertsEnabled,
        'sound': soundEnabled ?? _settings.soundEnabled,
        'vibration': vibrationEnabled ?? _settings.vibrationEnabled,
      };

      await _storageService.saveAlertSettings(alertSettings);

      _settings = _settings.copyWith(
        alertsEnabled: alertSettings['enabled'],
        soundEnabled: alertSettings['sound'],
        vibrationEnabled: alertSettings['vibration'],
        hasUnsavedChanges: false,
        lastSavedTimestamp: DateTime.now().toIso8601String(),
      );

      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error saving alert settings: $e');
      return false;
    }
  }

  Future<bool> saveSettings() async {
    try {
      // Save all settings
      await Future.wait([
        updateEspIpAddress(_settings.espIpAddress),
        updateThresholds(
          lowWaterThreshold: _settings.lowWaterThreshold,
          highTurbidityThreshold: _settings.highTurbidityThreshold,
          lowBatteryThreshold: _settings.lowBatteryThreshold,
        ),
        updateAlertSettings(
          alertsEnabled: _settings.alertsEnabled,
          soundEnabled: _settings.soundEnabled,
          vibrationEnabled: _settings.vibrationEnabled,
        ),
      ]);

      _settings = _settings.copyWith(
        hasUnsavedChanges: false,
        lastSavedTimestamp: DateTime.now().toIso8601String(),
      );
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error saving settings: $e');
      return false;
    }
  }

  Future<bool> connectToEsp() async {
    if (_settings.espIpAddress.isEmpty) {
      return false;
    }

    try {
      await _webSocketService.connect(_settings.espIpAddress);
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error connecting to ESP: $e');
      return false;
    }
  }

  void disconnectFromEsp() {
    _webSocketService.disconnect();
    notifyListeners();
  }

  Future<bool> testConnection() async {
    if (_settings.espIpAddress.isEmpty) {
      return false;
    }

    try {
      // Create a temporary connection for testing
      final testService = WebSocketService();
      await testService.connect(_settings.espIpAddress);
      final isConnected = testService.isConnected;
      testService.disconnect();
      return isConnected;
    } catch (e) {
      debugPrint('Connection test failed: $e');
      return false;
    }
  }

  // Add missing methods that UI widgets expect
  Future<void> clearAllData() async {
    await clearData();
  }

  Future<bool> clearData() async {
    try {
      await _storageService.clearAll();
      _settings = SettingsModel();
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error clearing data: $e');
      return false;
    }
  }

  Future<void> resetToDefaults() async {
    _settings = SettingsModel();
    await updateEspIpAddress('');
    await updateThresholds(
      lowWaterThreshold: 20.0,
      highTurbidityThreshold: 10.0,
      lowBatteryThreshold: 20.0,
    );
    await updateAlertSettings(
      alertsEnabled: true,
      soundEnabled: true,
      vibrationEnabled: true,
    );
  }
}
