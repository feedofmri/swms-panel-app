/// Settings-specific model for configuration data
class SettingsModel {
  final String espIpAddress;
  final double reservoirMinLevel;
  final double turbidityMax;
  final bool isConnected;
  final bool hasUnsavedChanges;
  final String? lastSavedTimestamp;

  SettingsModel({
    this.espIpAddress = '',
    this.reservoirMinLevel = 20.0,
    this.turbidityMax = 15.0,
    this.isConnected = false,
    this.hasUnsavedChanges = false,
    this.lastSavedTimestamp,
  });

  /// Create a copy with updated values
  SettingsModel copyWith({
    String? espIpAddress,
    double? reservoirMinLevel,
    double? turbidityMax,
    bool? isConnected,
    bool? hasUnsavedChanges,
    String? lastSavedTimestamp,
  }) {
    return SettingsModel(
      espIpAddress: espIpAddress ?? this.espIpAddress,
      reservoirMinLevel: reservoirMinLevel ?? this.reservoirMinLevel,
      turbidityMax: turbidityMax ?? this.turbidityMax,
      isConnected: isConnected ?? this.isConnected,
      hasUnsavedChanges: hasUnsavedChanges ?? this.hasUnsavedChanges,
      lastSavedTimestamp: lastSavedTimestamp ?? this.lastSavedTimestamp,
    );
  }

  /// Check if all required settings are valid
  bool get isValid {
    return espIpAddress.isNotEmpty &&
           reservoirMinLevel > 0 &&
           reservoirMinLevel <= 100 &&
           turbidityMax > 0;
  }

  /// Get validation errors
  List<String> get validationErrors {
    final errors = <String>[];

    if (espIpAddress.isEmpty) {
      errors.add('ESP IP address is required');
    }

    if (reservoirMinLevel <= 0 || reservoirMinLevel > 100) {
      errors.add('Reservoir minimum level must be between 1% and 100%');
    }

    if (turbidityMax <= 0) {
      errors.add('Turbidity maximum must be greater than 0');
    }

    return errors;
  }

  /// Convert to map for storage
  Map<String, dynamic> toMap() {
    return {
      'espIpAddress': espIpAddress,
      'reservoirMinLevel': reservoirMinLevel,
      'turbidityMax': turbidityMax,
      'lastSavedTimestamp': lastSavedTimestamp,
    };
  }

  /// Create from map
  factory SettingsModel.fromMap(Map<String, dynamic> map) {
    return SettingsModel(
      espIpAddress: map['espIpAddress'] ?? '',
      reservoirMinLevel: (map['reservoirMinLevel'] ?? 20.0).toDouble(),
      turbidityMax: (map['turbidityMax'] ?? 15.0).toDouble(),
      lastSavedTimestamp: map['lastSavedTimestamp'],
    );
  }

  @override
  String toString() {
    return 'SettingsModel(espIp: $espIpAddress, reservoirMin: $reservoirMinLevel%, turbidityMax: $turbidityMax, isValid: $isValid)';
  }
}
