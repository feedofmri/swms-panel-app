import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/utils/app_theme.dart';
import '../../../core/utils/helpers.dart';
import '../../../core/utils/constants.dart';
import '../../../core/models/pump_status.dart';
import '../viewmodel/controls_viewmodel.dart';
import '../widgets/pump_control_card.dart';
import '../widgets/system_control_card.dart';
import '../widgets/command_status_card.dart';

/// Controls screen for managing pumps and system controls
class ControlsScreen extends StatelessWidget {
  const ControlsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('System Controls'),
        actions: [
          Consumer<ControlsViewModel>(
            builder: (context, viewModel, child) {
              return IconButton(
                icon: const Icon(Icons.emergency),
                onPressed: viewModel.canSendCommands
                    ? () => _showEmergencyStopDialog(context, viewModel)
                    : null,
                tooltip: 'Emergency Stop',
              );
            },
          ),
        ],
      ),
      body: Consumer<ControlsViewModel>(
        builder: (context, viewModel, child) {
          return SingleChildScrollView(
            padding: AppConstants.defaultPadding,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Connection Status
                _buildConnectionStatus(context, viewModel),
                const SizedBox(height: 16),

                // System Status Summary
                _buildSystemStatusSummary(context, viewModel),
                const SizedBox(height: 16),

                // Pump Controls
                Text(
                  'Pump Controls',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),

                // First row with Pump 1 and 2
                Row(
                  children: [
                    Expanded(
                      child: PumpControlCard(
                        pumpName: 'Pump 1',
                        pumpStatus: _stringToPumpStatus(viewModel.pump1Status),
                        isConnected: viewModel.isConnected,
                        canControl: viewModel.canSendCommands,
                        onToggle: () => _handlePumpToggle(context, viewModel, 1),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: PumpControlCard(
                        pumpName: 'Pump 2',
                        pumpStatus: _stringToPumpStatus(viewModel.pump2Status),
                        isConnected: viewModel.isConnected,
                        canControl: viewModel.canSendCommands,
                        onToggle: () => _handlePumpToggle(context, viewModel, 2),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Second row with Pump 3
                Row(
                  children: [
                    Expanded(
                      child: PumpControlCard(
                        pumpName: 'Pump 3',
                        pumpStatus: _stringToPumpStatus(viewModel.pump3Status),
                        isConnected: viewModel.isConnected,
                        canControl: viewModel.canSendCommands,
                        onToggle: () => _handlePumpToggle(context, viewModel, 3),
                      ),
                    ),
                    const Expanded(child: SizedBox()), // Empty space to balance the row
                  ],
                ),

                const SizedBox(height: 24),

                // System Controls
                Text(
                  'System Controls',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),

                SystemControlCard(
                  viewModel: viewModel,
                  onSilenceBuzzer: () => _handleSilenceBuzzer(context, viewModel),
                  onEmergencyStop: () => _showEmergencyStopDialog(context, viewModel),
                ),

                const SizedBox(height: 16),

                // Command Status
                if (viewModel.lastCommandResult != null)
                  CommandStatusCard(
                    message: viewModel.lastCommandResult!,
                    timestamp: DateTime.now(), // Use current time since model doesn't have lastCommandSent
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  /// Build connection status indicator
  Widget _buildConnectionStatus(BuildContext context, ControlsViewModel viewModel) {
    final isConnected = viewModel.isConnected;
    final statusColor = isConnected ? AppTheme.connectedColor : AppTheme.disconnectedColor;
    final statusText = isConnected ? 'Connected' : 'Disconnected';
    final statusIcon = isConnected ? Icons.wifi : Icons.wifi_off;

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
          Icon(
            statusIcon,
            color: statusColor,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  statusText,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: statusColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  isConnected
                      ? 'Controls are available'
                      : 'Connect to ESP8266 to control devices',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: statusColor.withOpacity(0.8),
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: statusColor,
              shape: BoxShape.circle,
            ),
          ),
        ],
      ),
    );
  }

  /// Build system status summary
  Widget _buildSystemStatusSummary(BuildContext context, ControlsViewModel viewModel) {
    return Card(
      child: Padding(
        padding: AppConstants.cardPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.dashboard,
                  color: AppTheme.primaryColor,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'System Status',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  child: _buildStatusItem(
                    context,
                    'Active Pumps',
                    '${viewModel.runningPumpsCount}/3',
                    viewModel.isAnyPumpRunning ? AppTheme.successColor : AppTheme.disconnectedColor,
                  ),
                ),
                Expanded(
                  child: _buildStatusItem(
                    context,
                    'System Status',
                    viewModel.statusSummary,
                    viewModel.isConnected ? AppTheme.primaryColor : AppTheme.disconnectedColor,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Build status item
  Widget _buildStatusItem(BuildContext context, String label, String value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: AppTheme.textSecondary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: color,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  /// Handle pump toggle
  Future<void> _handlePumpToggle(
    BuildContext context,
    ControlsViewModel viewModel,
    int pumpNumber,
  ) async {
    if (!viewModel.canSendCommands) {
      AppHelpers.showErrorSnackBar(context, 'Cannot send command - check connection');
      return;
    }

    bool success = false;
    if (pumpNumber == 1) {
      await viewModel.togglePump1();
      success = true; // togglePump1 returns void, assume success
    } else if (pumpNumber == 2) {
      await viewModel.togglePump2();
      success = true; // togglePump2 returns void, assume success
    } else {
      await viewModel.togglePump3();
      success = true; // togglePump3 returns void, assume success
    }

    if (context.mounted) {
      if (success) {
        AppHelpers.showSuccessSnackBar(context, 'Pump $pumpNumber command sent');
      } else {
        AppHelpers.showErrorSnackBar(context, 'Failed to control Pump $pumpNumber');
      }
    }
  }

  /// Handle silence buzzer
  Future<void> _handleSilenceBuzzer(
    BuildContext context,
    ControlsViewModel viewModel,
  ) async {
    if (!viewModel.canSendCommands) {
      AppHelpers.showErrorSnackBar(context, 'Cannot send command - check connection');
      return;
    }

    final success = await viewModel.silenceBuzzer();

    if (context.mounted) {
      if (success) {
        AppHelpers.showSuccessSnackBar(context, 'Buzzer silenced');
      } else {
        AppHelpers.showErrorSnackBar(context, 'Failed to silence buzzer');
      }
    }
  }

  /// Show emergency stop confirmation dialog
  Future<void> _showEmergencyStopDialog(
    BuildContext context,
    ControlsViewModel viewModel,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              Icons.emergency,
              color: AppTheme.errorColor,
            ),
            const SizedBox(width: 8),
            const Text('Emergency Stop'),
          ],
        ),
        content: const Text(
          'This will immediately stop all pumps. Are you sure you want to proceed?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.errorColor,
              foregroundColor: Colors.white,
            ),
            child: const Text('Emergency Stop'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      await viewModel.emergencyStopAllPumps();

      if (context.mounted) {
        AppHelpers.showSuccessSnackBar(context, 'Emergency stop completed');
      }
    }
  }

  /// Convert string status to PumpStatus object
  PumpStatus _stringToPumpStatus(String status) {
    final isRunning = status.toUpperCase() == 'ON';
    return PumpStatus(
      pumpId: 'pump', // Generic pump ID
      isOn: isRunning,
    );
  }
}
