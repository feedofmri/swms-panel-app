/// Model for raw serial data received from ESP8266
class EspSerialData {
  final String rawMessage;
  final DateTime timestamp;
  final EspDataType dataType;

  EspSerialData({
    required this.rawMessage,
    DateTime? timestamp,
    EspDataType? dataType,
  }) : timestamp = timestamp ?? DateTime.now(),
       dataType = dataType ?? _parseDataType(rawMessage);

  /// Factory constructor to create from raw message
  factory EspSerialData.fromRawMessage(String message) {
    return EspSerialData(rawMessage: message);
  }

  /// Determine the type of data based on content
  static EspDataType _parseDataType(String message) {
    final lowerMessage = message.toLowerCase();

    if (lowerMessage.contains('sensor') || lowerMessage.contains('reading')) {
      return EspDataType.sensorReading;
    } else if (lowerMessage.contains('error') || lowerMessage.contains('failed')) {
      return EspDataType.error;
    } else if (lowerMessage.contains('connected') || lowerMessage.contains('wifi')) {
      return EspDataType.status;
    } else if (lowerMessage.contains('pump') || lowerMessage.contains('relay')) {
      return EspDataType.control;
    }

    return EspDataType.general;
  }

  /// Check if this message contains numeric sensor data
  bool get hasNumericData {
    final numericPattern = RegExp(r'\d+\.?\d*');
    return numericPattern.hasMatch(rawMessage);
  }

  /// Extract numeric values from the message
  List<double> get numericValues {
    final numericPattern = RegExp(r'\d+\.?\d*');
    final matches = numericPattern.allMatches(rawMessage);
    return matches.map((match) => double.tryParse(match.group(0)!) ?? 0.0).toList();
  }

  /// Check if message indicates an error condition
  bool get isError => dataType == EspDataType.error;

  /// Check if message is a status update
  bool get isStatus => dataType == EspDataType.status;

  @override
  String toString() {
    return 'EspSerialData(type: $dataType, message: "$rawMessage", time: ${timestamp.toLocal()})';
  }

  /// Convert to JSON for storage or transmission
  Map<String, dynamic> toJson() {
    return {
      'raw_message': rawMessage,
      'timestamp': timestamp.toIso8601String(),
      'data_type': dataType.name,
    };
  }

  /// Create from JSON
  factory EspSerialData.fromJson(Map<String, dynamic> json) {
    return EspSerialData(
      rawMessage: json['raw_message'] ?? '',
      timestamp: DateTime.tryParse(json['timestamp'] ?? '') ?? DateTime.now(),
      dataType: EspDataType.values.firstWhere(
        (type) => type.name == json['data_type'],
        orElse: () => EspDataType.general,
      ),
    );
  }
}

/// Types of data that can be received from ESP
enum EspDataType {
  sensorReading,
  control,
  status,
  error,
  general,
}

extension EspDataTypeExtension on EspDataType {
  String get displayName {
    switch (this) {
      case EspDataType.sensorReading:
        return 'Sensor Reading';
      case EspDataType.control:
        return 'Control Action';
      case EspDataType.status:
        return 'Status Update';
      case EspDataType.error:
        return 'Error';
      case EspDataType.general:
        return 'General';
    }
  }

  String get icon {
    switch (this) {
      case EspDataType.sensorReading:
        return '📊';
      case EspDataType.control:
        return '🎛️';
      case EspDataType.status:
        return '✅';
      case EspDataType.error:
        return '❌';
      case EspDataType.general:
        return '💬';
    }
  }
}
