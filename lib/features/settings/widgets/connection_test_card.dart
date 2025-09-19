import 'package:flutter/material.dart';
import '../../../core/utils/app_theme.dart';
import '../../../core/utils/helpers.dart';
import '../../../core/utils/constants.dart';
import '../viewmodel/settings_viewmodel.dart';

/// Connection test card for testing ESP8266 connectivity
class ConnectionTestCard extends StatefulWidget {
  final SettingsViewModel viewModel;

  const ConnectionTestCard({
    super.key,
    required this.viewModel,
  });

  @override
  State<ConnectionTestCard> createState() => _ConnectionTestCardState();
}

class _ConnectionTestCardState extends State<ConnectionTestCard> {
  bool _isTesting = false;

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
                  Icons.network_check,
                  color: AppTheme.primaryColor,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'Connection Management',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Connection status
            _buildConnectionStatus(),
            const SizedBox(height: 16),

            // Action buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _canTestConnection() ? _testConnection : null,
                    icon: _isTesting
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.wifi_find),
                    label: Text(_isTesting ? 'Testing...' : 'Test Connection'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: widget.viewModel.isConnected
                      ? ElevatedButton.icon(
                          onPressed: _disconnect,
                          icon: const Icon(Icons.wifi_off),
                          label: const Text('Disconnect'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.errorColor,
                            foregroundColor: Colors.white,
                          ),
                        )
                      : ElevatedButton.icon(
                          onPressed: _canConnect() ? _connect : null,
                          icon: const Icon(Icons.wifi),
                          label: const Text('Connect'),
                        ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Build connection status display
  Widget _buildConnectionStatus() {
    final isConnected = widget.viewModel.isConnected;
    final statusColor = isConnected ? AppTheme.successColor : AppTheme.disconnectedColor;
    final statusIcon = isConnected ? Icons.wifi : Icons.wifi_off;
    final statusText = isConnected ? 'Connected' : 'Disconnected';
    final currentIp = widget.viewModel.espIpAddress;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: statusColor.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                statusIcon,
                color: statusColor,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                statusText,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: statusColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          if (currentIp.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              isConnected
                  ? 'Connected to: $currentIp'
                  : 'Last IP: $currentIp',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: statusColor.withOpacity(0.8),
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// Check if connection test can be performed
  bool _canTestConnection() {
    return !_isTesting &&
           widget.viewModel.espIpAddress.isNotEmpty &&
           widget.viewModel.validateIpAddress(widget.viewModel.espIpAddress);
  }

  /// Check if connection can be established
  bool _canConnect() {
    return !widget.viewModel.isConnected &&
           widget.viewModel.espIpAddress.isNotEmpty &&
           widget.viewModel.validateIpAddress(widget.viewModel.espIpAddress);
  }

  /// Test connection
  Future<void> _testConnection() async {
    setState(() {
      _isTesting = true;
    });

    try {
      final success = await widget.viewModel.testConnection();

      if (mounted) {
        if (success) {
          AppHelpers.showSuccessSnackBar(context, 'Connection test successful');
        } else {
          AppHelpers.showErrorSnackBar(context, 'Connection test failed');
        }
      }
    } finally {
      if (mounted) {
        setState(() {
          _isTesting = false;
        });
      }
    }
  }

  /// Connect to ESP
  Future<void> _connect() async {
    final success = await widget.viewModel.connectToEsp();

    if (mounted) {
      if (success) {
        AppHelpers.showSuccessSnackBar(context, 'Connecting to ESP8266...');
      } else {
        AppHelpers.showErrorSnackBar(context, 'Failed to initiate connection');
      }
    }
  }

  /// Disconnect from ESP
  void _disconnect() {
    widget.viewModel.disconnectFromEsp();
    AppHelpers.showSuccessSnackBar(context, 'Disconnected from ESP8266');
  }
}
