import 'package:flutter/material.dart';
import '../../../core/models/alert.dart';
import '../../../core/utils/app_theme.dart';

/// Filter chips for filtering alerts by level
class AlertFilterChips extends StatelessWidget {
  final AlertLevel? selectedFilter;
  final ValueChanged<AlertLevel?> onFilterChanged;

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

          // Individual level filter chips
          ...AlertLevel.values.map((level) {
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilterChip(
                label: Text(level.displayName),
                selected: selectedFilter == level,
                onSelected: (selected) {
                  onFilterChanged(selected ? level : null);
                },
                selectedColor: _getAlertColor(level).withOpacity(0.2),
                checkmarkColor: _getAlertColor(level),
                avatar: selectedFilter == level
                    ? null
                    : Icon(
                        _getAlertIcon(level),
                        size: 16,
                        color: _getAlertColor(level),
                      ),
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  /// Get alert icon based on level
  IconData _getAlertIcon(AlertLevel level) {
    switch (level) {
      case AlertLevel.info:
        return Icons.info_outline;
      case AlertLevel.warning:
        return Icons.warning_amber;
      case AlertLevel.critical:
        return Icons.error_outline;
      case AlertLevel.emergency:
        return Icons.emergency;
    }
  }

  /// Get alert color based on level
  Color _getAlertColor(AlertLevel level) {
    switch (level) {
      case AlertLevel.info:
        return Colors.blue;
      case AlertLevel.warning:
        return AppTheme.warningColor;
      case AlertLevel.critical:
        return AppTheme.errorColor;
      case AlertLevel.emergency:
        return Colors.deepOrange;
    }
  }
}
