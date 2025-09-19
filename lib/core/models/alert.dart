/// Model for alerts and notifications
class Alert {
  final String id;
  final String message;
  final AlertLevel level;
  final DateTime timestamp;
  final bool isRead;
  final String? source;

  Alert({
    required this.id,
    required this.message,
    required this.level,
    DateTime? timestamp,
    this.isRead = false,
    this.source,
  }) : timestamp = timestamp ?? DateTime.now();

  /// Create a copy with updated values
  Alert copyWith({
    String? id,
    String? message,
    AlertLevel? level,
    DateTime? timestamp,
    bool? isRead,
    String? source,
  }) {
    return Alert(
      id: id ?? this.id,
      message: message ?? this.message,
      level: level ?? this.level,
      timestamp: timestamp ?? this.timestamp,
      isRead: isRead ?? this.isRead,
      source: source ?? this.source,
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'message': message,
      'level': level.toString(),
      'timestamp': timestamp.toIso8601String(),
      'isRead': isRead,
      'source': source,
    };
  }

  /// Create from JSON
  factory Alert.fromJson(Map<String, dynamic> json) {
    return Alert(
      id: json['id'],
      message: json['message'],
      level: AlertLevel.values.firstWhere(
        (e) => e.toString() == json['level'],
        orElse: () => AlertLevel.info,
      ),
      timestamp: DateTime.parse(json['timestamp']),
      isRead: json['isRead'] ?? false,
      source: json['source'],
    );
  }

  /// Generate unique ID for alert
  static String generateId() {
    return DateTime.now().millisecondsSinceEpoch.toString();
  }

  @override
  String toString() {
    return 'Alert(id: $id, message: $message, level: $level, timestamp: $timestamp, isRead: $isRead)';
  }
}

/// Alert severity levels
enum AlertLevel {
  info,
  warning,
  critical,
  emergency;

  /// Get color for alert level
  String get colorName {
    switch (this) {
      case AlertLevel.info:
        return 'blue';
      case AlertLevel.warning:
        return 'orange';
      case AlertLevel.critical:
        return 'red';
      case AlertLevel.emergency:
        return 'darkred';
    }
  }

  /// Get display name
  String get displayName {
    switch (this) {
      case AlertLevel.info:
        return 'Info';
      case AlertLevel.warning:
        return 'Warning';
      case AlertLevel.critical:
        return 'Critical';
      case AlertLevel.emergency:
        return 'Emergency';
    }
  }
}
