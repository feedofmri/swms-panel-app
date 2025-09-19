import 'package:flutter/material.dart';
import '../../../core/utils/app_theme.dart';
import '../../../core/utils/helpers.dart';
import '../../../core/utils/constants.dart';

/// Command status card for showing last command result
class CommandStatusCard extends StatelessWidget {
  final String message;
  final DateTime? timestamp;

  const CommandStatusCard({
    super.key,
    required this.message,
    this.timestamp,
  });

  @override
  Widget build(BuildContext context) {
    final isSuccess = message.toLowerCase().contains('success');
    final isError = message.toLowerCase().contains('failed') ||
                   message.toLowerCase().contains('error');

    Color statusColor;
    IconData statusIcon;

    if (isSuccess) {
      statusColor = AppTheme.successColor;
      statusIcon = Icons.check_circle;
    } else if (isError) {
      statusColor = AppTheme.errorColor;
      statusIcon = Icons.error;
    } else {
      statusColor = AppTheme.warningColor;
      statusIcon = Icons.info;
    }

    return Card(
      color: statusColor.withOpacity(0.05),
      child: Padding(
        padding: AppConstants.cardPadding,
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                statusIcon,
                color: statusColor,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Command Status',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: statusColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    message,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  if (timestamp != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Sent ${AppHelpers.formatTimestamp(timestamp!)}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
