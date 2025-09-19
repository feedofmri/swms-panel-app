import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';
import '../models/sensor_data.dart';
import '../models/alert.dart';

/// Service for persistent data storage using SharedPreferences
class StorageService {
  static final StorageService _instance = StorageService._internal();
  factory StorageService() => _instance;
  StorageService._internal();

  SharedPreferences? _prefs;

  // Storage keys
  static const String _keyEspIpAddress = 'esp_ip_address';
  static const String _keyReservoirMinLevel = 'reservoir_min_level';
  static const String _keyTurbidityMax = 'turbidity_max';
  static const String _keyLastSensorData = 'last_sensor_data';
  static const String _keyAlerts = 'alerts';
  static const String _keyConnectionSettings = 'connection_settings';

  /// Initialize storage service
  Future<void> initialize() async {
    _prefs ??= await SharedPreferences.getInstance();
    debugPrint('StorageService: Initialized successfully');
  }

  /// Ensure preferences are loaded
  Future<void> _ensureInitialized() async {
    if (_prefs == null) {
      await initialize();
    }
  }

  // ESP IP Address
  Future<void> saveEspIpAddress(String ipAddress) async {
    await _ensureInitialized();
    await _prefs!.setString(_keyEspIpAddress, ipAddress);
    debugPrint('StorageService: Saved ESP IP address: $ipAddress');
  }

  Future<String?> getEspIpAddress() async {
    await _ensureInitialized();
    return _prefs!.getString(_keyEspIpAddress);
  }

  // Reservoir minimum level threshold
  Future<void> saveReservoirMinLevel(double level) async {
    await _ensureInitialized();
    await _prefs!.setDouble(_keyReservoirMinLevel, level);
    debugPrint('StorageService: Saved reservoir min level: $level');
  }

  Future<double> getReservoirMinLevel() async {
    await _ensureInitialized();
    return _prefs!.getDouble(_keyReservoirMinLevel) ?? 20.0; // Default 20%
  }

  // Turbidity maximum threshold
  Future<void> saveTurbidityMax(double turbidity) async {
    await _ensureInitialized();
    await _prefs!.setDouble(_keyTurbidityMax, turbidity);
    debugPrint('StorageService: Saved turbidity max: $turbidity');
  }

  Future<double> getTurbidityMax() async {
    await _ensureInitialized();
    return _prefs!.getDouble(_keyTurbidityMax) ?? 15.0; // Default 15 NTU
  }

  // Last sensor data
  Future<void> saveLastSensorData(SensorData sensorData) async {
    await _ensureInitialized();
    final jsonString = json.encode(sensorData.toJson());
    await _prefs!.setString(_keyLastSensorData, jsonString);
    debugPrint('StorageService: Saved last sensor data');
  }

  Future<SensorData?> getLastSensorData() async {
    await _ensureInitialized();
    final jsonString = _prefs!.getString(_keyLastSensorData);
    if (jsonString != null) {
      try {
        final jsonData = json.decode(jsonString);
        return SensorData.fromJson(jsonData);
      } catch (e) {
        debugPrint('StorageService: Failed to parse last sensor data: $e');
        return null;
      }
    }
    return null;
  }

  // Alerts
  Future<void> saveAlerts(List<Alert> alerts) async {
    await _ensureInitialized();
    final alertsJson = alerts.map((alert) => alert.toJson()).toList();
    final jsonString = json.encode(alertsJson);
    await _prefs!.setString(_keyAlerts, jsonString);
    debugPrint('StorageService: Saved ${alerts.length} alerts');
  }

  Future<List<Alert>> getAlerts() async {
    await _ensureInitialized();
    final jsonString = _prefs!.getString(_keyAlerts);
    if (jsonString != null) {
      try {
        final List<dynamic> alertsJson = json.decode(jsonString);
        return alertsJson.map((json) => Alert.fromJson(json)).toList();
      } catch (e) {
        debugPrint('StorageService: Failed to parse alerts: $e');
        return [];
      }
    }
    return [];
  }

  // Connection settings
  Future<void> saveConnectionSettings({
    required String ipAddress,
    required double reservoirMinLevel,
    required double turbidityMax,
  }) async {
    await _ensureInitialized();
    final settings = {
      'ipAddress': ipAddress,
      'reservoirMinLevel': reservoirMinLevel,
      'turbidityMax': turbidityMax,
      'lastUpdated': DateTime.now().toIso8601String(),
    };
    await _prefs!.setString(_keyConnectionSettings, json.encode(settings));
    debugPrint('StorageService: Saved connection settings');
  }

  Future<Map<String, dynamic>?> getConnectionSettings() async {
    await _ensureInitialized();
    final jsonString = _prefs!.getString(_keyConnectionSettings);
    if (jsonString != null) {
      try {
        return json.decode(jsonString);
      } catch (e) {
        debugPrint('StorageService: Failed to parse connection settings: $e');
        return null;
      }
    }
    return null;
  }

  // Clear all data
  Future<void> clearAllData() async {
    await _ensureInitialized();
    await _prefs!.clear();
    debugPrint('StorageService: Cleared all stored data');
  }

  // Clear specific data
  Future<void> clearAlerts() async {
    await _ensureInitialized();
    await _prefs!.remove(_keyAlerts);
    debugPrint('StorageService: Cleared stored alerts');
  }

  Future<void> clearSensorData() async {
    await _ensureInitialized();
    await _prefs!.remove(_keyLastSensorData);
    debugPrint('StorageService: Cleared stored sensor data');
  }

  // Utility methods
  Future<bool> hasStoredData() async {
    await _ensureInitialized();
    return _prefs!.containsKey(_keyEspIpAddress);
  }

  Future<Map<String, dynamic>> getAllSettings() async {
    await _ensureInitialized();
    return {
      'espIpAddress': await getEspIpAddress(),
      'reservoirMinLevel': await getReservoirMinLevel(),
      'turbidityMax': await getTurbidityMax(),
      'hasLastSensorData': _prefs!.containsKey(_keyLastSensorData),
      'alertsCount': (await getAlerts()).length,
    };
  }
}
