import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/models/alert.dart';
import '../../../core/utils/app_theme.dart';
import '../../../core/utils/helpers.dart';
import '../../../core/utils/constants.dart';
import '../viewmodel/alerts_viewmodel.dart';
import '../widgets/alert_card.dart';
import '../widgets/alert_summary_card.dart';
import '../widgets/alert_filter_chips.dart';

/// Alerts screen for viewing and managing system alerts
class AlertsScreen extends StatefulWidget {
  const AlertsScreen({super.key});

  @override
  State<AlertsScreen> createState() => _AlertsScreenState();
}

class _AlertsScreenState extends State<AlertsScreen> {
  AlertLevel? _selectedFilter;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('System Alerts'),
        actions: [
          Consumer<AlertsViewModel>(
            builder: (context, viewModel, child) {
              return PopupMenuButton<String>(
                onSelected: (value) => _handleMenuAction(context, viewModel, value),
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'mark_all_read',
                    child: Row(
                      children: [
                        Icon(Icons.mark_email_read),
                        SizedBox(width: 8),
                        Text('Mark All Read'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'clear_all',
                    child: Row(
                      children: [
                        Icon(Icons.clear_all),
                        SizedBox(width: 8),
                        Text('Clear All'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'refresh',
                    child: Row(
                      children: [
                        Icon(Icons.refresh),
                        SizedBox(width: 8),
                        Text('Refresh'),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
      body: Consumer<AlertsViewModel>(
        builder: (context, viewModel, child) {
          return RefreshIndicator(
            onRefresh: viewModel.refresh,
            child: Column(
              children: [
                // Alert Summary Card
                Padding(
                  padding: AppConstants.defaultPadding,
                  child: AlertSummaryCard(viewModel: viewModel),
                ),

                // Filter Chips
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: AlertFilterChips(
                    selectedFilter: _selectedFilter,
                    onFilterChanged: (filter) {
                      setState(() {
                        _selectedFilter = filter;
                      });
                    },
                  ),
                ),

                const SizedBox(height: 8),

                // Alerts List
                Expanded(
                  child: _buildAlertsList(context, viewModel),
                ),
              ],
            ),
          );
        },
      ),
      floatingActionButton: Consumer<AlertsViewModel>(
        builder: (context, viewModel, child) {
          // Show FAB only if there are unread alerts
          if (viewModel.unreadAlerts.isEmpty) return const SizedBox.shrink();

          return FloatingActionButton.extended(
            onPressed: () => viewModel.markAllAlertsAsRead(),
            icon: const Icon(Icons.mark_email_read),
            label: Text('Mark ${viewModel.unreadAlerts.length} Read'),
          );
        },
      ),
    );
  }

  /// Build the alerts list
  Widget _buildAlertsList(BuildContext context, AlertsViewModel viewModel) {
    final alerts = _getFilteredAlerts(viewModel);

    if (alerts.isEmpty) {
      return _buildEmptyState(context);
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: alerts.length,
      itemBuilder: (context, index) {
        final alert = alerts[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: AlertCard(
            alert: alert,
            onTap: () => _handleAlertTap(context, viewModel, alert),
            onDelete: () => _handleAlertDelete(context, viewModel, alert),
          ),
        );
      },
    );
  }

  /// Build empty state widget
  Widget _buildEmptyState(BuildContext context) {
    final hasFilter = _selectedFilter != null;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            hasFilter ? Icons.filter_list_off : Icons.notifications_off,
            size: 64,
            color: Colors.grey,
          ),
          const SizedBox(height: 16),
          Text(
            hasFilter ? 'No alerts match the filter' : 'No alerts yet',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            hasFilter
                ? 'Try changing the filter or check back later'
                : 'System alerts will appear here when detected',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.grey,
            ),
            textAlign: TextAlign.center,
          ),
          if (hasFilter) ...[
            const SizedBox(height: 16),
            TextButton(
              onPressed: () {
                setState(() {
                  _selectedFilter = null;
                });
              },
              child: const Text('Clear Filter'),
            ),
          ],
        ],
      ),
    );
  }

  /// Get filtered alerts based on selected filter
  List<Alert> _getFilteredAlerts(AlertsViewModel viewModel) {
    if (_selectedFilter == null) {
      return viewModel.alerts;
    }
    return viewModel.getAlertsByLevel(_selectedFilter!);
  }

  /// Handle menu action selection
  Future<void> _handleMenuAction(
    BuildContext context,
    AlertsViewModel viewModel,
    String action,
  ) async {
    switch (action) {
      case 'mark_all_read':
        await viewModel.markAllAlertsAsRead();
        if (context.mounted) {
          AppHelpers.showSuccessSnackBar(context, 'All alerts marked as read');
        }
        break;
      case 'clear_all':
        await _confirmClearAll(context, viewModel);
        break;
      case 'refresh':
        await viewModel.refresh();
        if (context.mounted) {
          AppHelpers.showSuccessSnackBar(context, 'Alerts refreshed');
        }
        break;
    }
  }

  /// Handle alert tap
  void _handleAlertTap(BuildContext context, AlertsViewModel viewModel, Alert alert) {
    if (!alert.isRead) {
      viewModel.markAlertAsRead(alert.id);
    }

    // Show alert details dialog
    _showAlertDetailsDialog(context, alert);
  }

  /// Handle alert delete
  Future<void> _handleAlertDelete(
    BuildContext context,
    AlertsViewModel viewModel,
    Alert alert,
  ) async {
    final confirmed = await _showDeleteConfirmationDialog(context, alert);
    if (confirmed == true) {
      await viewModel.deleteAlert(alert.id);
      if (context.mounted) {
        AppHelpers.showSuccessSnackBar(context, 'Alert deleted');
      }
    }
  }

  /// Show alert details dialog
  void _showAlertDetailsDialog(BuildContext context, Alert alert) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              _getAlertIcon(alert.level),
              color: _getAlertColor(alert.level),
            ),
            const SizedBox(width: 8),
            Text(alert.level.displayName),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              alert.message,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 16),
            Text(
              'Time: ${AppHelpers.formatDetailedTimestamp(alert.timestamp)}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            if (alert.source != null) ...[
              const SizedBox(height: 4),
              Text(
                'Source: ${alert.source}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  /// Show delete confirmation dialog
  Future<bool?> _showDeleteConfirmationDialog(BuildContext context, Alert alert) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Alert'),
        content: const Text('Are you sure you want to delete this alert?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  /// Confirm clear all alerts
  Future<void> _confirmClearAll(BuildContext context, AlertsViewModel viewModel) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear All Alerts'),
        content: const Text('Are you sure you want to clear all alerts? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Clear All'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await viewModel.clearAllAlerts();
      if (context.mounted) {
        AppHelpers.showSuccessSnackBar(context, 'All alerts cleared');
      }
    }
  }

  /// Get alert icon based on level
  IconData _getAlertIcon(AlertLevel level) {
    switch (level) {
      case AlertLevel.info:
        return Icons.info;
      case AlertLevel.warning:
        return Icons.warning;
      case AlertLevel.critical:
        return Icons.error;
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
