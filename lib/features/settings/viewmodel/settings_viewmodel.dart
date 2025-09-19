import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../../core/services/websocket_service.dart';
import '../../../core/services/storage_service.dart';
import '../../../core/utils/helpers.dart';
import '../../../core/utils/constants.dart';
import '../model/settings_model.dart';

/// ViewModel for the Settings screen following MVVM pattern
class SettingsViewModel extends ChangeNotifier {
  final WebSocketService _webSocketService;
  final StorageService _storageService;

  SettingsModel _model = SettingsModel();
  SettingsModel _originalModel = SettingsModel();

  SettingsViewModel({
    required WebSocketService webSocketService,
    required StorageService storageService,
  }) : _webSocketService = webSocketService,
       _storageService = storageService {
    _initialize();
  }

  // Getters
  SettingsModel get model => _model;
  String get espIpAddress => _model.espIpAddress;
  double get reservoirMinLevel => _model.reservoirMinLevel;
  double get turbidityMax => _model.turbidityMax;
  bool get isConnected => _model.isConnected;
  bool get hasUnsavedChanges => _model.hasUnsavedChanges;
  bool get isValid => _model.isValid;
  List<String> get validationErrors => _model.validationErrors;
  String? get lastSavedTimestamp => _model.lastSavedTimestamp;

  /// Initialize settings
  Future<void> _initialize() async {
    await _loadSettings();
    _listenToConnectionChanges();
  }

  /// Load settings from storage
  Future<void> _loadSettings() async {
    try {
      final espIp = await _storageService.getEspIpAddress() ?? '';
      final reservoirMin = await _storageService.getReservoirMinLevel();
      final turbidityMax = await _storageService.getTurbidityMax();

      final connectionSettings = await _storageService.getConnectionSettings();
      final lastSaved = connectionSettings?['lastUpdated'];

      _model = SettingsModel(
        espIpAddress: espIp,
        reservoirMinLevel: reservoirMin,
        turbidityMax: turbidityMax,
        isConnected: _webSocketService.isConnected,
        lastSavedTimestamp: lastSaved,
      );

      _originalModel = _model;
      notifyListeners();

      debugPrint('SettingsViewModel: Loaded settings: $_model');
    } catch (e) {
      debugPrint('SettingsViewModel: Failed to load settings: $e');
    }
  }

  /// Listen to WebSocket connection changes
  void _listenToConnectionChanges() {
    _webSocketService.addListener(_onConnectionStatusChanged);
  }

  /// Handle WebSocket connection status changes
  void _onConnectionStatusChanged() {
    _updateModel(isConnected: _webSocketService.isConnected);
  }

  /// Update ESP IP address
  void updateEspIpAddress(String ipAddress) {
    _updateModel(
      espIpAddress: ipAddress.trim(),
      hasUnsavedChanges: true,
    );
  }

  /// Update reservoir minimum level
  void updateReservoirMinLevel(double level) {
    _updateModel(
      reservoirMinLevel: level,
      hasUnsavedChanges: true,
    );
  }

  /// Update turbidity maximum
  void updateTurbidityMax(double turbidity) {
    _updateModel(
      turbidityMax: turbidity,
      hasUnsavedChanges: true,
    );
  }

  /// Validate IP address format
  bool validateIpAddress(String ip) {
    return AppHelpers.isValidIpAddress(ip);
  }

  /// Save settings
  Future<bool> saveSettings() async {
    if (!_model.isValid) {
      debugPrint('SettingsViewModel: Cannot save invalid settings');
      return false;
    }

    try {
      // Save individual settings
      await _storageService.saveEspIpAddress(_model.espIpAddress);
      await _storageService.saveReservoirMinLevel(_model.reservoirMinLevel);
      await _storageService.saveTurbidityMax(_model.turbidityMax);

      // Save connection settings
      await _storageService.saveConnectionSettings(
        ipAddress: _model.espIpAddress,
        reservoirMinLevel: _model.reservoirMinLevel,
        turbidityMax: _model.turbidityMax,
      );

      _updateModel(
        hasUnsavedChanges: false,
        lastSavedTimestamp: DateTime.now().toIso8601String(),
      );

      _originalModel = _model;

      debugPrint('SettingsViewModel: Settings saved successfully');
      return true;
    } catch (e) {
      debugPrint('SettingsViewModel: Failed to save settings: $e');
      return false;
    }
  }

  /// Reset settings to defaults
  void resetToDefaults() {
    _updateModel(
      espIpAddress: '',
      reservoirMinLevel: AppConstants.defaultReservoirMinLevel,
      turbidityMax: AppConstants.defaultTurbidityMax,
      hasUnsavedChanges: true,
    );
  }

  /// Discard unsaved changes
  void discardChanges() {
    _model = _originalModel.copyWith(
      isConnected: _webSocketService.isConnected,
    );
    notifyListeners();
  }

  /// Test connection with current IP
  Future<bool> testConnection() async {
    if (_model.espIpAddress.isEmpty || !validateIpAddress(_model.espIpAddress)) {
      debugPrint('SettingsViewModel: Invalid IP address for connection test');
      return false;
    }

    try {
      debugPrint('SettingsViewModel: Testing connection to ${_model.espIpAddress}');

      // Disconnect current connection if any
      if (_webSocketService.isConnected) {
        _webSocketService.disconnect();
        await Future.delayed(const Duration(seconds: 1));
      }

      // Attempt to connect
      await _webSocketService.connect(_model.espIpAddress);

      // Wait a moment to see if connection establishes
      await Future.delayed(const Duration(seconds: 3));

      final success = _webSocketService.isConnected;
      debugPrint('SettingsViewModel: Connection test result: $success');

      return success;
    } catch (e) {
      debugPrint('SettingsViewModel: Connection test error: $e');
      return false;
    }
  }

  /// Connect to ESP with current settings
  Future<bool> connectToEsp() async {
    if (!validateIpAddress(_model.espIpAddress)) {
      debugPrint('SettingsViewModel: Invalid IP address for connection');
      return false;
    }

    try {
      await _webSocketService.connect(_model.espIpAddress);
      debugPrint('SettingsViewModel: Connection initiated to ${_model.espIpAddress}');
      return true;
    } catch (e) {
      debugPrint('SettingsViewModel: Failed to connect: $e');
      return false;
    }
  }

  /// Disconnect from ESP
  void disconnectFromEsp() {
    _webSocketService.disconnect();
    debugPrint('SettingsViewModel: Disconnected from ESP');
  }

  /// Clear all stored data
  Future<bool> clearAllData() async {
    try {
      await _storageService.clearAllData();

      _model = SettingsModel(
        isConnected: _webSocketService.isConnected,
      );
      _originalModel = _model;

      notifyListeners();
      debugPrint('SettingsViewModel: All data cleared');
      return true;
    } catch (e) {
      debugPrint('SettingsViewModel: Failed to clear data: $e');
      return false;
    }
  }

  /// Get settings summary
  Map<String, dynamic> getSettingsSummary() {
    return {
      'ESP IP': _model.espIpAddress.isNotEmpty ? _model.espIpAddress : 'Not set',
      'Reservoir Min Level': '${_model.reservoirMinLevel.toStringAsFixed(1)}%',
      'Turbidity Max': '${_model.turbidityMax.toStringAsFixed(1)} NTU',
      'Connection Status': _model.isConnected ? 'Connected' : 'Disconnected',
      'Settings Valid': _model.isValid ? 'Yes' : 'No',
      'Unsaved Changes': _model.hasUnsavedChanges ? 'Yes' : 'No',
      'Last Saved': _model.lastSavedTimestamp ?? 'Never',
    };
  }

  /// Update the model and notify listeners
  void _updateModel({
    String? espIpAddress,
    double? reservoirMinLevel,
    double? turbidityMax,
    bool? isConnected,
    bool? hasUnsavedChanges,
    String? lastSavedTimestamp,
  }) {
    final wasValid = _model.isValid;

    _model = _model.copyWith(
      espIpAddress: espIpAddress,
      reservoirMinLevel: reservoirMinLevel,
      turbidityMax: turbidityMax,
      isConnected: isConnected,
      hasUnsavedChanges: hasUnsavedChanges,
      lastSavedTimestamp: lastSavedTimestamp,
    );

    // Check if we need to recalculate unsaved changes
    if (hasUnsavedChanges == null && (espIpAddress != null ||
        reservoirMinLevel != null || turbidityMax != null)) {
      final hasChanges = _model.espIpAddress != _originalModel.espIpAddress ||
                        _model.reservoirMinLevel != _originalModel.reservoirMinLevel ||
                        _model.turbidityMax != _originalModel.turbidityMax;
      _model = _model.copyWith(hasUnsavedChanges: hasChanges);
    }

    notifyListeners();

    // Log validation status changes
    if (wasValid != _model.isValid) {
      debugPrint('SettingsViewModel: Validation status changed to ${_model.isValid}');
    }
  }

  @override
  void dispose() {
    _webSocketService.removeListener(_onConnectionStatusChanged);
    super.dispose();
  }
}
