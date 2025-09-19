import '../../../core/models/sensor_data.dart';
import '../../../core/utils/constants.dart';

/// Dashboard-specific model for organizing sensor data
class DashboardModel {
  final SensorData? currentData;
  final bool isDataAvailable;
  final DateTime? lastUpdate;
  final bool isConnected;
  final String connectionStatus;

  DashboardModel({
    this.currentData,
    this.isDataAvailable = false,
    this.lastUpdate,
    this.isConnected = false,
    this.connectionStatus = 'Disconnected',
  });

  /// Create a copy with updated values
  DashboardModel copyWith({
    SensorData? currentData,
    bool? isDataAvailable,
    DateTime? lastUpdate,
    bool? isConnected,
    String? connectionStatus,
  }) {
    return DashboardModel(
      currentData: currentData ?? this.currentData,
      isDataAvailable: isDataAvailable ?? this.isDataAvailable,
      lastUpdate: lastUpdate ?? this.lastUpdate,
      isConnected: isConnected ?? this.isConnected,
      connectionStatus: connectionStatus ?? this.connectionStatus,
    );
  }

  /// Get reservoir tank status
  TankStatus get reservoirStatus {
    if (currentData == null) return TankStatus.empty;
    return TankStatus.fromLevel(currentData!.reservoirLevel);
  }

  /// Get house tank status
  TankStatus get houseTankStatus {
    if (currentData == null) return TankStatus.empty;
    return TankStatus.fromLevel(currentData!.houseTankLevel);
  }

  /// Check if any critical alerts are present
  bool get hasCriticalAlerts {
    if (currentData == null) return false;
    return currentData!.reservoirLevel <= AppConstants.criticalReservoirLevel ||
           currentData!.battery < AppConstants.criticalBatteryLevel;
  }

  /// Check if any warnings are present
  bool get hasWarnings {
    if (currentData == null) return false;
    return currentData!.reservoirLevel <= AppConstants.warningReservoirLevel ||
           currentData!.battery < AppConstants.warningBatteryLevel ||
           currentData!.turbidity > AppConstants.defaultTurbidityMax;
  }

  /// Get overall system status
  SystemStatus get systemStatus {
    if (!isConnected) return SystemStatus.disconnected;
    if (hasCriticalAlerts) return SystemStatus.critical;
    if (hasWarnings) return SystemStatus.warning;
    return SystemStatus.normal;
  }

  /// Check if data is fresh (less than 30 seconds old)
  bool get isDataFresh {
    if (lastUpdate == null) return false;
    return DateTime.now().difference(lastUpdate!).inSeconds < 30;
  }
}

/// System status enumeration
enum SystemStatus {
  normal,
  warning,
  critical,
  disconnected;

  String get displayText {
    switch (this) {
      case SystemStatus.normal:
        return 'System Normal';
      case SystemStatus.warning:
        return 'Warnings Present';
      case SystemStatus.critical:
        return 'Critical Alerts';
      case SystemStatus.disconnected:
        return 'System Disconnected';
    }
  }
}
