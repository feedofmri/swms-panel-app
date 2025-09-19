import '../../../core/models/alert.dart';

/// Alerts-specific model for organizing alert data
class AlertsModel {
  final List<Alert> alerts;
  final List<Alert> unreadAlerts;
  final int totalAlerts;
  final int criticalAlerts;
  final int warningAlerts;
  final Alert? latestAlert;

  AlertsModel({
    this.alerts = const [],
    this.unreadAlerts = const [],
    this.totalAlerts = 0,
    this.criticalAlerts = 0,
    this.warningAlerts = 0,
    this.latestAlert,
  });

  /// Create AlertsModel from list of alerts
  factory AlertsModel.fromAlerts(List<Alert> alertsList) {
    final unread = alertsList.where((alert) => !alert.isRead).toList();
    final critical = alertsList.where((alert) =>
        alert.level == AlertLevel.critical || alert.level == AlertLevel.emergency).length;
    final warning = alertsList.where((alert) => alert.level == AlertLevel.warning).length;
    final latest = alertsList.isNotEmpty ? alertsList.first : null;

    return AlertsModel(
      alerts: alertsList,
      unreadAlerts: unread,
      totalAlerts: alertsList.length,
      criticalAlerts: critical,
      warningAlerts: warning,
      latestAlert: latest,
    );
  }

  /// Create a copy with updated values
  AlertsModel copyWith({
    List<Alert>? alerts,
    List<Alert>? unreadAlerts,
    int? totalAlerts,
    int? criticalAlerts,
    int? warningAlerts,
    Alert? latestAlert,
  }) {
    return AlertsModel(
      alerts: alerts ?? this.alerts,
      unreadAlerts: unreadAlerts ?? this.unreadAlerts,
      totalAlerts: totalAlerts ?? this.totalAlerts,
      criticalAlerts: criticalAlerts ?? this.criticalAlerts,
      warningAlerts: warningAlerts ?? this.warningAlerts,
      latestAlert: latestAlert ?? this.latestAlert,
    );
  }

  /// Get alerts filtered by level
  List<Alert> getAlertsByLevel(AlertLevel level) {
    return alerts.where((alert) => alert.level == level).toList();
  }

  /// Get alerts from today
  List<Alert> getTodayAlerts() {
    final today = DateTime.now();
    return alerts.where((alert) {
      final alertDate = alert.timestamp;
      return alertDate.year == today.year &&
             alertDate.month == today.month &&
             alertDate.day == today.day;
    }).toList();
  }

  /// Check if there are any unread critical alerts
  bool get hasUnreadCriticalAlerts {
    return unreadAlerts.any((alert) =>
        alert.level == AlertLevel.critical || alert.level == AlertLevel.emergency);
  }

  /// Get alert summary string
  String get alertSummary {
    if (totalAlerts == 0) return 'No alerts';
    if (criticalAlerts > 0) return '$criticalAlerts critical, $warningAlerts warnings';
    if (warningAlerts > 0) return '$warningAlerts warnings';
    return '$totalAlerts alerts';
  }
}
