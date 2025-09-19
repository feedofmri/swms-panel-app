import 'package:flutter/material.dart';
import '../models/sensor_data.dart';
import '../models/alert.dart';
import 'constants.dart';
import 'app_theme.dart';

/// Utility functions for the SWMS Panel app
class AppHelpers {

  /// Format percentage values
  static String formatPercentage(double value) {
    return '${value.toStringAsFixed(1)}%';
  }

  /// Format voltage values
  static String formatVoltage(double value) {
    return '${value.toStringAsFixed(1)}V';
  }

  /// Format turbidity values
  static String formatTurbidity(double value) {
    return '${value.toStringAsFixed(1)} NTU';
  }

  /// Get turbidity status label
  static String getTurbidityStatus(double turbidity, double maxThreshold) {
    return turbidity <= maxThreshold ? 'Good' : 'Poor';
  }

  /// Get turbidity status color
  static Color getTurbidityColor(double turbidity, double maxThreshold) {
    return turbidity <= maxThreshold ? AppTheme.successColor : AppTheme.errorColor;
  }

  /// Get tank level color based on percentage
  static Color getTankLevelColor(double level) {
    if (level <= 10) return AppTheme.tankEmptyColor;
    if (level <= 25) return AppTheme.tankLowColor;
    if (level <= 60) return AppTheme.tankMediumColor;
    if (level <= 85) return AppTheme.tankHighColor;
    return AppTheme.tankFullColor;
  }

  /// Get tank status from level
  static TankStatus getTankStatus(double level) {
    return TankStatus.fromLevel(level);
  }

  /// Get battery level color
  static Color getBatteryColor(double voltage) {
    if (voltage < AppConstants.criticalBatteryLevel) return AppTheme.errorColor;
    if (voltage < AppConstants.warningBatteryLevel) return AppTheme.warningColor;
    return AppTheme.successColor;
  }

  /// Get pump status color
  static Color getPumpStatusColor(String status) {
    return status.toUpperCase() == 'ON' ? AppTheme.successColor : AppTheme.disconnectedColor;
  }

  /// Get filter tank status color
  static Color getFilterTankColor(String status) {
    return status.toLowerCase() == 'wet' ? AppTheme.successColor : AppTheme.warningColor;
  }

  /// Format timestamp for display
  static String formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return '${timestamp.day}/${timestamp.month}/${timestamp.year}';
    }
  }

  /// Format detailed timestamp
  static String formatDetailedTimestamp(DateTime timestamp) {
    return '${timestamp.day.toString().padLeft(2, '0')}/'
           '${timestamp.month.toString().padLeft(2, '0')}/'
           '${timestamp.year} '
           '${timestamp.hour.toString().padLeft(2, '0')}:'
           '${timestamp.minute.toString().padLeft(2, '0')}';
  }

  /// Validate IP address format
  static bool isValidIpAddress(String ip) {
    final ipRegex = RegExp(r'^(?:[0-9]{1,3}\.){3}[0-9]{1,3}$');
    if (!ipRegex.hasMatch(ip)) return false;

    final parts = ip.split('.');
    for (final part in parts) {
      final value = int.tryParse(part);
      if (value == null || value < 0 || value > 255) return false;
    }
    return true;
  }

  /// Generate alert from sensor data
  static Alert? generateAlertFromSensorData(SensorData data, {
    double? reservoirMinLevel,
    double? turbidityMax,
  }) {
    final minLevel = reservoirMinLevel ?? AppConstants.defaultReservoirMinLevel;
    final maxTurbidity = turbidityMax ?? AppConstants.defaultTurbidityMax;

    // Check for critical reservoir level
    if (data.reservoirLevel <= AppConstants.criticalReservoirLevel) {
      return Alert(
        id: Alert.generateId(),
        message: 'Critical: Reservoir level critically low (${formatPercentage(data.reservoirLevel)})',
        level: AlertLevel.critical,
        source: 'reservoir_sensor',
      );
    }

    // Check for low reservoir level
    if (data.reservoirLevel <= minLevel) {
      return Alert(
        id: Alert.generateId(),
        message: 'Warning: Reservoir level low (${formatPercentage(data.reservoirLevel)})',
        level: AlertLevel.warning,
        source: 'reservoir_sensor',
      );
    }

    // Check for high turbidity
    if (data.turbidity > maxTurbidity) {
      return Alert(
        id: Alert.generateId(),
        message: 'Warning: Water turbidity high (${formatTurbidity(data.turbidity)})',
        level: AlertLevel.warning,
        source: 'turbidity_sensor',
      );
    }

    // Check for low battery
    if (data.battery < AppConstants.criticalBatteryLevel) {
      return Alert(
        id: Alert.generateId(),
        message: 'Critical: Battery voltage low (${formatVoltage(data.battery)})',
        level: AlertLevel.critical,
        source: 'battery_monitor',
      );
    }

    // Check for existing alert in data
    if (data.alert != null && data.alert!.isNotEmpty) {
      return Alert(
        id: Alert.generateId(),
        message: data.alert!,
        level: AlertLevel.warning,
        source: 'esp8266',
      );
    }

    return null;
  }

  /// Show snackbar message
  static void showSnackBar(BuildContext context, String message, {
    Color? backgroundColor,
    Duration duration = const Duration(seconds: 3),
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: backgroundColor,
        duration: duration,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  /// Show error snackbar
  static void showErrorSnackBar(BuildContext context, String message) {
    showSnackBar(context, message, backgroundColor: AppTheme.errorColor);
  }

  /// Show success snackbar
  static void showSuccessSnackBar(BuildContext context, String message) {
    showSnackBar(context, message, backgroundColor: AppTheme.successColor);
  }

  /// Show warning snackbar
  static void showWarningSnackBar(BuildContext context, String message) {
    showSnackBar(context, message, backgroundColor: AppTheme.warningColor);
  }

  /// Get connection status from WebSocket state
  static ConnectionStatus getConnectionStatus(bool isConnected, bool isConnecting) {
    if (isConnecting) return ConnectionStatus.connecting;
    if (isConnected) return ConnectionStatus.connected;
    return ConnectionStatus.disconnected;
  }

  /// Calculate data freshness indicator
  static String getDataFreshness(DateTime lastUpdate) {
    final now = DateTime.now();
    final difference = now.difference(lastUpdate);

    if (difference.inSeconds < 10) return 'Live';
    if (difference.inSeconds < 30) return 'Recent';
    if (difference.inMinutes < 5) return 'Stale';
    return 'Old';
  }

  /// Get data freshness color
  static Color getDataFreshnessColor(DateTime lastUpdate) {
    final now = DateTime.now();
    final difference = now.difference(lastUpdate);

    if (difference.inSeconds < 30) return AppTheme.successColor;
    if (difference.inMinutes < 5) return AppTheme.warningColor;
    return AppTheme.errorColor;
  }
}
