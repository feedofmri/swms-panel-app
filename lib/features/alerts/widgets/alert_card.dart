import 'package:flutter/material.dart';
import '../../../core/models/alert.dart';
import '../../../core/utils/app_theme.dart';
import '../../../core/utils/helpers.dart';
import '../../../core/utils/constants.dart';

/// Alert card widget for displaying individual alerts
class AlertCard extends StatelessWidget {
  final Alert alert;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;

  const AlertCard({
    super.key,
    required this.alert,
    this.onTap,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final alertColor = _getAlertColor(alert.level);
    final alertIcon = _getAlertIcon(alert.level);

    return Card(
      elevation: alert.isRead ? 2 : 4,
      color: alert.isRead ? null : alertColor.withOpacity(0.05),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppConstants.cardBorderRadius),
        child: Padding(
          padding: AppConstants.cardPadding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row
              Row(
                children: [
                  // Alert level indicator
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: alertColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Icon(
                      alertIcon,
                      color: alertColor,
                      size: 16,
                    ),
                  ),
                  const SizedBox(width: 8),

                  // Alert level badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: alertColor,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      alert.level.displayName.toUpperCase(),
                      style: AppTextStyles.statusIndicator.copyWith(
                        fontSize: 10,
                      ),
                    ),
                  ),

                  const Spacer(),

                  // Unread indicator
                  if (!alert.isRead)
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: alertColor,
                        shape: BoxShape.circle,
                      ),
                    ),

                  const SizedBox(width: 8),

                  // Delete button
                  if (onDelete != null)
                    IconButton(
                      onPressed: onDelete,
                      icon: const Icon(Icons.delete_outline),
                      iconSize: 18,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(
                        minWidth: 24,
                        minHeight: 24,
                      ),
                    ),
                ],
              ),

              const SizedBox(height: 8),

              // Alert message
              Text(
                alert.message,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  fontWeight: alert.isRead ? FontWeight.normal : FontWeight.w500,
                  color: alert.isRead ? AppTheme.textSecondary : AppTheme.textPrimary,
                ),
              ),

              const SizedBox(height: 8),

              // Footer with timestamp and source
              Row(
                children: [
                  Icon(
                    Icons.access_time,
                    size: 14,
                    color: AppTheme.textLight,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    AppHelpers.formatTimestamp(alert.timestamp),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppTheme.textLight,
                    ),
                  ),

                  if (alert.source != null) ...[
                    const SizedBox(width: 16),
                    Icon(
                      Icons.sensors,
                      size: 14,
                      color: AppTheme.textLight,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      alert.source!,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.textLight,
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
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
