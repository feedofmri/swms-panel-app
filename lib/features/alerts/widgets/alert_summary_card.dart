import 'package:flutter/material.dart';
import '../../../core/utils/app_theme.dart';
import '../../../core/utils/constants.dart';
import '../viewmodel/alerts_viewmodel.dart';

/// Alert summary card showing overview statistics
class AlertSummaryCard extends StatelessWidget {
  final AlertsViewModel viewModel;

  const AlertSummaryCard({
    super.key,
    required this.viewModel,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: AppConstants.cardPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Icon(
                  Icons.analytics_outlined,
                  color: AppTheme.primaryColor,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'Alert Summary',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Statistics row
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    context,
                    'Total',
                    viewModel.totalAlerts.toString(),
                    AppTheme.primaryColor,
                    Icons.notifications,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    context,
                    'Critical',
                    viewModel.criticalAlerts.toString(),
                    AppTheme.errorColor,
                    Icons.error,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    context,
                    'Warnings',
                    viewModel.warningAlerts.toString(),
                    AppTheme.warningColor,
                    Icons.warning,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    context,
                    'Unread',
                    viewModel.unreadAlerts.toString(),
                    AppTheme.successColor,
                    Icons.mark_email_unread,
                  ),
                ),
              ],
            ),

            // Latest alert info if available
            if (viewModel.latestAlert != null) ...[
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                    Icons.schedule,
                    size: 16,
                    color: AppTheme.textSecondary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Latest: ${_formatLatestAlert(viewModel.latestAlert!)}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// Build individual stat item
  Widget _buildStatItem(
    BuildContext context,
    String label,
    String value,
    Color color,
    IconData icon,
  ) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: color,
            size: 20,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            color: color,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: AppTheme.textSecondary,
          ),
        ),
      ],
    );
  }

  /// Format latest alert info
  String _formatLatestAlert(AlertData alert) {
    final now = DateTime.now();
    final diff = now.difference(alert.timestamp);

    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}
