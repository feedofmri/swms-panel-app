import 'package:flutter/material.dart';
import '../../../core/utils/app_theme.dart';
import '../../../core/utils/constants.dart';
import '../viewmodel/controls_viewmodel.dart';

/// System control card for buzzer and emergency controls
class SystemControlCard extends StatelessWidget {
  final ControlsViewModel viewModel;
  final VoidCallback? onSilenceBuzzer;
  final VoidCallback? onEmergencyStop;

  const SystemControlCard({
    super.key,
    required this.viewModel,
    this.onSilenceBuzzer,
    this.onEmergencyStop,
  });

  @override
  Widget build(BuildContext context) {
    final canControl = viewModel.canSendCommands;

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
                  Icons.settings,
                  color: AppTheme.primaryColor,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'System Controls',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Buzzer control
            _buildControlRow(
              context,
              icon: Icons.volume_off,
              title: 'Silence Buzzer',
              subtitle: 'Stop audible alerts',
              buttonText: 'Silence',
              buttonColor: AppTheme.warningColor,
              enabled: canControl,
              onPressed: onSilenceBuzzer,
            ),

            const SizedBox(height: 12),

            // Emergency stop
            _buildControlRow(
              context,
              icon: Icons.emergency,
              title: 'Emergency Stop',
              subtitle: 'Stop all pumps immediately',
              buttonText: 'Emergency Stop',
              buttonColor: AppTheme.errorColor,
              enabled: canControl && viewModel.isAnyPumpRunning,
              onPressed: onEmergencyStop,
            ),

            const SizedBox(height: 12),

            // Status info
            if (!canControl)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: Colors.orange.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: Colors.orange,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Controls disabled - check connection or wait for pending command',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.orange,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// Build control row with icon, text, and button
  Widget _buildControlRow(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required String buttonText,
    required Color buttonColor,
    required bool enabled,
    VoidCallback? onPressed,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: buttonColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: enabled ? buttonColor : Colors.grey,
            size: 20,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: enabled ? AppTheme.textPrimary : Colors.grey,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                subtitle,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: enabled ? AppTheme.textSecondary : Colors.grey,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        ElevatedButton(
          onPressed: enabled ? onPressed : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: buttonColor,
            foregroundColor: Colors.white,
            disabledBackgroundColor: Colors.grey.withOpacity(0.3),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          ),
          child: Text(
            buttonText,
            style: const TextStyle(fontSize: 12),
          ),
        ),
      ],
    );
  }
}
