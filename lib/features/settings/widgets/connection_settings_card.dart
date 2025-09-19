import 'package:flutter/material.dart';
import '../../../core/utils/app_theme.dart';
import '../../../core/utils/constants.dart';
import '../viewmodel/settings_viewmodel.dart';

/// Connection settings card for ESP IP configuration
class ConnectionSettingsCard extends StatefulWidget {
  final SettingsViewModel viewModel;

  const ConnectionSettingsCard({
    super.key,
    required this.viewModel,
  });

  @override
  State<ConnectionSettingsCard> createState() => _ConnectionSettingsCardState();
}

class _ConnectionSettingsCardState extends State<ConnectionSettingsCard> {
  late TextEditingController _ipController;

  @override
  void initState() {
    super.initState();
    _ipController = TextEditingController(text: widget.viewModel.espIpAddress);
  }

  @override
  void dispose() {
    _ipController.dispose();
    super.dispose();
  }

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
                  Icons.wifi,
                  color: AppTheme.primaryColor,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'ESP8266 Connection',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // IP Address input
            TextFormField(
              controller: _ipController,
              decoration: InputDecoration(
                labelText: 'ESP8266 IP Address',
                hintText: '192.168.1.100',
                prefixIcon: const Icon(Icons.computer),
                helperText: 'Enter the IP address of your ESP8266 device',
                errorText: _getIpValidationError(),
              ),
              keyboardType: TextInputType.numberWithOptions(decimal: true),
              onChanged: (value) {
                widget.viewModel.updateEspIpAddress(value);
                setState(() {}); // Refresh validation display
              },
            ),
            const SizedBox(height: 16),

            // Connection info
            _buildConnectionInfo(),

            // Default WiFi info
            const SizedBox(height: 12),
            _buildWiFiInfo(),
          ],
        ),
      ),
    );
  }

  /// Get IP validation error message
  String? _getIpValidationError() {
    final ip = _ipController.text.trim();
    if (ip.isEmpty) return null;
    if (!widget.viewModel.validateIpAddress(ip)) {
      return 'Please enter a valid IP address (e.g., 192.168.1.100)';
    }
    return null;
  }

  /// Build connection info section
  Widget _buildConnectionInfo() {
    final isConnected = widget.viewModel.isConnected;
    final statusColor = isConnected ? AppTheme.successColor : AppTheme.disconnectedColor;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: statusColor.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            isConnected ? Icons.check_circle : Icons.cancel,
            color: statusColor,
            size: 16,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              isConnected ? 'Connected to ESP8266' : 'Not connected',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: statusColor,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Build WiFi info section
  Widget _buildWiFiInfo() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: Colors.blue.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.info_outline,
                color: Colors.blue,
                size: 16,
              ),
              const SizedBox(width: 8),
              Text(
                'Default ESP8266 WiFi Settings',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.blue,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _buildInfoRow('SSID', AppConstants.wifiSSID),
          _buildInfoRow('Password', AppConstants.wifiPassword),
          _buildInfoRow('WebSocket Port', AppConstants.defaultEspPort),
        ],
      ),
    );
  }

  /// Build info row
  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              '$label:',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.blue.withOpacity(0.8),
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w500,
                color: Colors.blue,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
