import 'package:flutter/material.dart';

/// Application constants and configuration
class AppConstants {
  // App Information
  static const String appName = 'SWMS Panel';
  static const String appVersion = '1.0.0';

  // ESP8266 Configuration
  static const String defaultEspPort = '81';
  static const String websocketProtocol = 'ws://';
  static const String wifiSSID = 'Prison Breakers';
  static const String wifiPassword = '#Syntax50';

  // Default Thresholds
  static const double defaultReservoirMinLevel = 20.0; // %
  static const double defaultTurbidityMax = 15.0; // NTU
  static const double defaultBatteryMin = 6.0; // Volts

  // UI Constants
  static const double cardBorderRadius = 12.0;
  static const double buttonBorderRadius = 8.0;
  static const EdgeInsets defaultPadding = EdgeInsets.all(16.0);
  static const EdgeInsets cardPadding = EdgeInsets.all(12.0);

  // Animation Durations
  static const Duration shortAnimation = Duration(milliseconds: 300);
  static const Duration mediumAnimation = Duration(milliseconds: 500);
  static const Duration longAnimation = Duration(milliseconds: 800);

  // Refresh Intervals
  static const Duration dataRefreshInterval = Duration(seconds: 5);
  static const Duration connectionCheckInterval = Duration(seconds: 10);

  // Alert Thresholds
  static const double criticalReservoirLevel = 10.0; // %
  static const double warningReservoirLevel = 25.0; // %
  static const double criticalBatteryLevel = 5.5; // Volts
  static const double warningBatteryLevel = 6.5; // Volts

  // Storage Keys
  static const String storageKeyPrefix = 'swms_';

  // Network Timeouts
  static const Duration connectionTimeout = Duration(seconds: 10);
  static const Duration reconnectDelay = Duration(seconds: 3);
  static const int maxReconnectAttempts = 5;
}

/// Status indicators
enum ConnectionStatus {
  disconnected,
  connecting,
  connected,
  error,
  reconnecting;

  Color get color {
    switch (this) {
      case ConnectionStatus.disconnected:
        return Colors.grey;
      case ConnectionStatus.connecting:
        return Colors.orange;
      case ConnectionStatus.connected:
        return Colors.green;
      case ConnectionStatus.error:
        return Colors.red;
      case ConnectionStatus.reconnecting:
        return Colors.amber;
    }
  }

  String get displayText {
    switch (this) {
      case ConnectionStatus.disconnected:
        return 'Disconnected';
      case ConnectionStatus.connecting:
        return 'Connecting...';
      case ConnectionStatus.connected:
        return 'Connected';
      case ConnectionStatus.error:
        return 'Connection Error';
      case ConnectionStatus.reconnecting:
        return 'Reconnecting...';
    }
  }
}

/// Tank status indicators
enum TankStatus {
  empty,
  low,
  medium,
  high,
  full;

  static TankStatus fromLevel(double level) {
    if (level <= 10) return TankStatus.empty;
    if (level <= 25) return TankStatus.low;
    if (level <= 60) return TankStatus.medium;
    if (level <= 85) return TankStatus.high;
    return TankStatus.full;
  }

  Color get color {
    switch (this) {
      case TankStatus.empty:
        return Colors.red;
      case TankStatus.low:
        return Colors.orange;
      case TankStatus.medium:
        return Colors.yellow;
      case TankStatus.high:
        return Colors.lightGreen;
      case TankStatus.full:
        return Colors.green;
    }
  }

  String get displayText {
    switch (this) {
      case TankStatus.empty:
        return 'Empty';
      case TankStatus.low:
        return 'Low';
      case TankStatus.medium:
        return 'Medium';
      case TankStatus.high:
        return 'High';
      case TankStatus.full:
        return 'Full';
    }
  }
}
