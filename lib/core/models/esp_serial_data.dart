import 'dart:convert';
import 'package:flutter/material.dart';
import 'sensor_data.dart';

/// Model for raw ESP8266 serial data
class EspSerialData {
  final String rawMessage;
  final DateTime timestamp;
  final Map<String, dynamic>? parsedData;
  final EspDataType dataType;

  EspSerialData({
    required this.rawMessage,
    DateTime? timestamp,
    this.parsedData,
    EspDataType? dataType,
  })  : timestamp = timestamp ?? DateTime.now(),
        dataType = dataType ?? _determineDataType(rawMessage);

  /// Factory constructor to create EspSerialData from raw message
  factory EspSerialData.fromRawMessage(String message) {
    final parsedData = _parseRawMessage(message);
    final dataType = _determineDataType(message);

    return EspSerialData(
      rawMessage: message,
      parsedData: parsedData,
      dataType: dataType,
    );
  }

  /// Determine the type of ESP data based on content
  static EspDataType _determineDataType(String message) {
    final lower = message.toLowerCase();
    if (lower.contains('error') || lower.contains('failed')) {
      return EspDataType.error;
    } else if (lower.contains('tank') ||
        lower.contains('pump') ||
        lower.contains('battery')) {
      return EspDataType.sensor;
    } else if (lower.contains('connected') || lower.contains('wifi')) {
      return EspDataType.system;
    } else {
      return EspDataType.debug;
    }
  }

  /// Check if this data contains numeric sensor values
  bool get hasNumericData =>
      parsedData != null && parsedData!.values.any((value) => value is num);

  /// Get numeric values from parsed data
  Map<String, num> get numericValues {
    if (parsedData == null) return {};
    return Map.fromEntries(
        parsedData!.entries
            .where((entry) => entry.value is num)
            .map((entry) => MapEntry(entry.key, entry.value as num)));
  }

  /// Parse raw ESP message and extract sensor values
  static Map<String, dynamic>? _parseRawMessage(String message) {
    try {
      // Handle different message formats that might come from ESP
      final trimmed = message.trim();

      // If it's already JSON, parse it
      if (trimmed.startsWith('{') && trimmed.endsWith('}')) {
        return json.decode(trimmed) as Map<String, dynamic>;
      }

      // Parse custom sensor data format
      // Example: "Tank1:75,Tank2:60,Pump1:ON,Pump2:OFF,Battery:85"
      if (trimmed.contains(':') && trimmed.contains(',')) {
        final data = <String, dynamic>{};
        final parts = trimmed.split(',');

        for (final part in parts) {
          final keyValue = part.split(':');
          if (keyValue.length == 2) {
            final key = keyValue[0].trim().toLowerCase();
            final value = keyValue[1].trim();

            // Try to parse as number, otherwise keep as string
            if (double.tryParse(value) != null) {
              data[key] = double.parse(value);
            } else {
              data[key] = value;
            }
          }
        }

        return data.isNotEmpty ? data : null;
      }

      // Parse line-based format where each line contains sensor info
      // Example: "Reservoir Level: 75%"
      final lines = trimmed.split('\n');
      final data = <String, dynamic>{};

      for (final line in lines) {
        if (line.contains(':')) {
          final parts = line.split(':');
          if (parts.length >= 2) {
            final key = parts[0].trim().toLowerCase().replaceAll(' ', '_');
            final valueStr = parts[1].trim().replaceAll('%', '');

            // Try to parse as number
            if (double.tryParse(valueStr) != null) {
              data[key] = double.parse(valueStr);
            } else {
              data[key] = valueStr;
            }
          }
        }
      }

      return data.isNotEmpty ? data : null;
    } catch (e) {
      // If parsing fails, return null
      return null;
    }
  }

  /// Convert to SensorData if possible
  SensorData? toSensorData() {
    if (parsedData == null) return null;

    try {
      // Map common field names to expected SensorData fields
      final mappedData = <String, dynamic>{};

      for (final entry in parsedData!.entries) {
        final key = entry.key.toLowerCase();
        final value = entry.value;

        // Map various possible field names to standard ones
        if (key.contains('reservoir') || key.contains('tank1')) {
          mappedData['reservoir_level'] = value;
        } else if (key.contains('house') || key.contains('tank2')) {
          mappedData['house_tank_level'] = value;
        } else if (key.contains('filter')) {
          mappedData['filter_tank'] = value;
        } else if (key.contains('turbidity') || key.contains('clarity')) {
          mappedData['turbidity'] = value;
        } else if (key.contains('pump1') || key == 'pump_1') {
          mappedData['pump1'] = value;
        } else if (key.contains('pump2') || key == 'pump_2') {
          mappedData['pump2'] = value;
        } else if (key.contains('battery') || key.contains('power')) {
          mappedData['battery'] = value;
        } else if (key.contains('alert') || key.contains('warning')) {
          mappedData['alert'] = value;
        }
      }

      // Create SensorData with default values for missing fields
      return SensorData.fromJson({
        'reservoir_level': mappedData['reservoir_level'] ?? 0,
        'house_tank_level': mappedData['house_tank_level'] ?? 0,
        'filter_tank': mappedData['filter_tank'] ?? 'unknown',
        'turbidity': mappedData['turbidity'] ?? 0,
        'pump1': mappedData['pump1'] ?? 'OFF',
        'pump2': mappedData['pump2'] ?? 'OFF',
        'battery': mappedData['battery'] ?? 0,
        'alert': mappedData['alert'],
      });
    } catch (e) {
      return null;
    }
  }

  @override
  String toString() {
    return 'EspSerialData(message: $rawMessage, timestamp: $timestamp, parsed: $parsedData)';
  }
}

/// Enum for different types of ESP data
enum EspDataType {
  sensor,
  system,
  debug,
  error,
  // Add the missing enum values that the UI expects
  status,
  sensorReading,
  control,
}

// Add extension methods for the ESP data type
extension EspDataTypeExtension on EspDataType {
  String get displayName {
    switch (this) {
      case EspDataType.sensor:
      case EspDataType.sensorReading:
        return 'Sensor';
      case EspDataType.system:
      case EspDataType.status:
        return 'Status';
      case EspDataType.debug:
        return 'Debug';
      case EspDataType.error:
        return 'Error';
      case EspDataType.control:
        return 'Control';
    }
  }

  IconData get icon {
    switch (this) {
      case EspDataType.sensor:
      case EspDataType.sensorReading:
        return Icons.sensors;
      case EspDataType.system:
      case EspDataType.status:
        return Icons.info;
      case EspDataType.debug:
        return Icons.bug_report;
      case EspDataType.error:
        return Icons.error;
      case EspDataType.control:
        return Icons.control_camera;
    }
  }
}
