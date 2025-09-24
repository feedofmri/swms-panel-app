import 'package:flutter/material.dart';
import '../../../core/utils/app_theme.dart';
import '../viewmodel/alerts_viewmodel.dart';

/// Filter chips for filtering alerts by severity
class AlertFilterChips extends StatelessWidget {
  final AlertSeverity? selectedFilter;
  final ValueChanged<AlertSeverity?> onFilterChanged;

  const AlertFilterChips({
    super.key,
    required this.selectedFilter,
    required this.onFilterChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          // All filter chip
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: const Text('All'),
              selected: selectedFilter == null,
              onSelected: (selected) {
                onFilterChanged(selected ? null : selectedFilter);
              },
              selectedColor: AppTheme.primaryColor.withOpacity(0.2),
              checkmarkColor: AppTheme.primaryColor,
            ),
          ),

          // Individual severity filter chips
          ...AlertSeverity.values.map((severity) {
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilterChip(
                label: Text(_getSeverityDisplayName(severity)),
                selected: selectedFilter == severity,
                onSelected: (selected) {
                  onFilterChanged(selected ? severity : null);
                },
                selectedColor: _getAlertColor(severity).withOpacity(0.2),
                checkmarkColor: _getAlertColor(severity),
                avatar: selectedFilter == severity
                    ? null
                    : Icon(
                        _getAlertIcon(severity),
                        size: 16,
                        color: _getAlertColor(severity),
                      ),
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  /// Get display name for severity
  String _getSeverityDisplayName(AlertSeverity severity) {
    switch (severity) {
      case AlertSeverity.info:
        return 'Info';
      case AlertSeverity.warning:
        return 'Warning';
      case AlertSeverity.critical:
        return 'Critical';
    }
  }

  /// Get alert icon based on severity
  IconData _getAlertIcon(AlertSeverity severity) {
    switch (severity) {
      case AlertSeverity.info:
        return Icons.info_outline;
      case AlertSeverity.warning:
        return Icons.warning_amber;
      case AlertSeverity.critical:
        return Icons.error_outline;
    }
  }

  /// Get alert color based on severity
  Color _getAlertColor(AlertSeverity severity) {
    switch (severity) {
      case AlertSeverity.info:
        return Colors.blue;
      case AlertSeverity.warning:
        return AppTheme.warningColor;
      case AlertSeverity.critical:
        return AppTheme.errorColor;
    }
  }
}
