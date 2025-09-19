import 'package:flutter/material.dart';
import '../../../core/utils/app_theme.dart';
import '../../../core/utils/constants.dart';

/// Pump status card widget for displaying pump on/off state
class PumpStatusCard extends StatelessWidget {
  final String title;
  final bool isOn;
  final bool isConnected;
  final VoidCallback? onTap;

  const PumpStatusCard({
    super.key,
    required this.title,
    required this.isOn,
    this.isConnected = true,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final statusColor = isConnected
        ? (isOn ? AppTheme.successColor : AppTheme.disconnectedColor)
        : Colors.grey;
    final statusText = isConnected
        ? (isOn ? 'ON' : 'OFF')
        : '--';

    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppConstants.cardBorderRadius),
        child: Padding(
          padding: AppConstants.cardPadding,
          child: Column(
            children: [
              // Header
              Row(
                children: [
                  Icon(
                    Icons.power,
                    color: statusColor,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      title,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: isConnected ? AppTheme.textPrimary : Colors.grey,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  if (!isConnected)
                    Icon(
                      Icons.cloud_off,
                      size: 16,
                      color: Colors.grey,
                    ),
                ],
              ),
              const SizedBox(height: 16),

              // Status indicator
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: statusColor.withOpacity(0.3),
                    width: 2,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      isOn ? Icons.power_settings_new : Icons.power_off,
                      color: statusColor,
                      size: 32,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      statusText,
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: statusColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // Status message
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  isConnected
                      ? (isOn ? 'Pump Running' : 'Pump Stopped')
                      : 'Connection Lost',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: statusColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
