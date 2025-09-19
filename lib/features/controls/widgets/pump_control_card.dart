import 'package:flutter/material.dart';
import '../../../core/models/pump_status.dart';
import '../../../core/utils/app_theme.dart';
import '../../../core/utils/helpers.dart';
import '../../../core/utils/constants.dart';

/// Pump control card widget for individual pump control
class PumpControlCard extends StatelessWidget {
  final String pumpName;
  final PumpStatus pumpStatus;
  final bool isConnected;
  final bool canControl;
  final VoidCallback? onToggle;

  const PumpControlCard({
    super.key,
    required this.pumpName,
    required this.pumpStatus,
    this.isConnected = true,
    this.canControl = true,
    this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final statusColor = isConnected
        ? (pumpStatus.isOn ? AppTheme.successColor : AppTheme.disconnectedColor)
        : Colors.grey;

    final canInteract = isConnected && canControl && onToggle != null;

    return Card(
      child: Padding(
        padding: AppConstants.cardPadding,
        child: Column(
          children: [
            // Header
            Row(
              children: [
                Icon(
                  Icons.water_damage,
                  color: statusColor,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    pumpName,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: isConnected ? AppTheme.textPrimary : Colors.grey,
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
            GestureDetector(
              onTap: canInteract ? onToggle : null,
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: statusColor.withOpacity(0.3),
                    width: 3,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      pumpStatus.isOn ? Icons.power_settings_new : Icons.power_off,
                      color: statusColor,
                      size: 40,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      isConnected
                          ? (pumpStatus.isOn ? 'ON' : 'OFF')
                          : '--',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: statusColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Control button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: canInteract ? onToggle : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: pumpStatus.isOn ? AppTheme.errorColor : AppTheme.successColor,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: Colors.grey.withOpacity(0.3),
                ),
                child: Text(
                  isConnected
                      ? (pumpStatus.isOn ? 'Turn OFF' : 'Turn ON')
                      : 'Disconnected',
                ),
              ),
            ),
            const SizedBox(height: 8),

            // Last toggled info
            if (isConnected && pumpStatus.lastToggled != null)
              Text(
                'Last toggled: ${AppHelpers.formatTimestamp(pumpStatus.lastToggled)}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppTheme.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),

            // Status message
            Container(
              width: double.infinity,
              margin: const EdgeInsets.only(top: 8),
              padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                _getStatusMessage(),
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
    );
  }

  /// Get status message based on pump state
  String _getStatusMessage() {
    if (!isConnected) return 'Connection Lost';
    if (!canControl) return 'Command Pending...';
    if (pumpStatus.isOn) return 'Pump Running';
    return 'Pump Stopped';
  }
}
