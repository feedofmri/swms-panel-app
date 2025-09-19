import 'package:flutter/material.dart';
import '../../../core/utils/app_theme.dart';
import '../viewmodel/dashboard_viewmodel.dart';

/// Connection status bar widget for showing WebSocket connection state
class ConnectionStatusBar extends StatelessWidget {
  final DashboardViewModel viewModel;

  const ConnectionStatusBar({
    super.key,
    required this.viewModel,
  });

  @override
  Widget build(BuildContext context) {
    final isConnected = viewModel.isConnected;
    final status = viewModel.connectionStatus;
    final freshness = viewModel.getDataFreshness();

    Color statusColor;
    IconData statusIcon;

    if (isConnected) {
      statusColor = AppTheme.connectedColor;
      statusIcon = Icons.wifi;
    } else if (status.contains('Connecting') || status.contains('Reconnecting')) {
      statusColor = AppTheme.connectingColor;
      statusIcon = Icons.wifi_protected_setup;
    } else {
      statusColor = AppTheme.disconnectedColor;
      statusIcon = Icons.wifi_off;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: statusColor.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          // Status icon with animation for connecting states
          if (status.contains('Connecting') || status.contains('Reconnecting'))
            SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(statusColor),
              ),
            )
          else
            Icon(
              statusIcon,
              color: statusColor,
              size: 20,
            ),

          const SizedBox(width: 12),

          // Status text
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  status,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: statusColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (isConnected && viewModel.model.lastUpdate != null)
                  Text(
                    'Data: $freshness',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: statusColor.withOpacity(0.8),
                    ),
                  ),
              ],
            ),
          ),

          // Connection indicator dot
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: statusColor,
              shape: BoxShape.circle,
              boxShadow: isConnected ? [
                BoxShadow(
                  color: statusColor.withOpacity(0.3),
                  blurRadius: 4,
                  spreadRadius: 1,
                ),
              ] : null,
            ),
          ),
        ],
      ),
    );
  }
}
