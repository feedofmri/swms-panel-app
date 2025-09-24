import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:percent_indicator/percent_indicator.dart';
import '../../../core/utils/app_theme.dart';
import '../../../core/utils/helpers.dart';
import '../../../core/utils/constants.dart';
import '../viewmodel/dashboard_viewmodel.dart';
import '../model/dashboard_model.dart';
import '../widgets/sensor_card.dart';
import '../widgets/tank_level_card.dart';
import '../widgets/pump_status_card.dart';
import '../widgets/connection_status_bar.dart';

/// Dashboard screen - main view of the SWMS Panel
class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('SWMS Dashboard'),
        actions: [
          Consumer<DashboardViewModel>(
            builder: (context, viewModel, child) {
              return IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: () async {
                  await viewModel.refresh();
                  if (context.mounted) {
                    AppHelpers.showSuccessSnackBar(context, 'Dashboard refreshed');
                  }
                },
              );
            },
          ),
        ],
      ),
      body: Consumer<DashboardViewModel>(
        builder: (context, viewModel, child) {
          return RefreshIndicator(
            onRefresh: viewModel.refresh,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: AppConstants.defaultPadding,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Connection Status Bar
                  ConnectionStatusBar(viewModel: viewModel),
                  const SizedBox(height: 16),

                  // System Status Card
                  _buildSystemStatusCard(context, viewModel),
                  const SizedBox(height: 16),

                  // Tank Levels Row
                  Row(
                    children: [
                      Expanded(
                        child: TankLevelCard(
                          title: 'Reservoir',
                          level: viewModel.reservoirPercentage,
                          icon: Icons.water_drop,
                          isConnected: viewModel.isConnected,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TankLevelCard(
                          title: 'House Tank',
                          level: viewModel.houseTankPercentage,
                          icon: Icons.home,
                          isConnected: viewModel.isConnected,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Water Quality and Battery Row
                  Row(
                    children: [
                      Expanded(
                        child: SensorCard(
                          title: 'Water Quality',
                          value: viewModel.isTurbidityGood ? 'Good' : 'Poor',
                          subtitle: AppHelpers.formatTurbidity(viewModel.turbidityValue),
                          icon: Icons.opacity,
                          color: AppHelpers.getTurbidityColor(
                            viewModel.turbidityValue,
                            AppConstants.defaultTurbidityMax,
                          ),
                          isConnected: viewModel.isConnected,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: SensorCard(
                          title: 'Battery',
                          value: AppHelpers.formatVoltage(viewModel.batteryVoltage),
                          subtitle: _getBatteryStatus(viewModel.batteryVoltage),
                          icon: Icons.battery_full,
                          color: AppHelpers.getBatteryColor(viewModel.batteryVoltage),
                          isConnected: viewModel.isConnected,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Filter Tank Status
                  SensorCard(
                    title: 'Filter Tank',
                    value: viewModel.filterTankStatus.toUpperCase(),
                    subtitle: viewModel.filterTankStatus.toLowerCase() == 'wet'
                        ? 'Filter is functioning'
                        : 'Check filter condition',
                    icon: Icons.filter_alt,
                    color: AppHelpers.getFilterTankColor(viewModel.filterTankStatus),
                    isConnected: viewModel.isConnected,
                  ),
                  const SizedBox(height: 16),

                  // Pump Status Row
                  Row(
                    children: [
                      Expanded(
                        child: PumpStatusCard(
                          title: 'Pump 1',
                          isOn: viewModel.isPump1On,
                          isConnected: viewModel.isConnected,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: PumpStatusCard(
                          title: 'Pump 2',
                          isOn: viewModel.isPump2On,
                          isConnected: viewModel.isConnected,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Current Alert (if any)
                  if (viewModel.currentAlert != null && viewModel.currentAlert!.isNotEmpty)
                    _buildAlertCard(context, viewModel.currentAlert!),

                  // Last Update Info
                  _buildLastUpdateInfo(context, viewModel),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  /// Build system status card
  Widget _buildSystemStatusCard(BuildContext context, DashboardViewModel viewModel) {
    final status = viewModel.systemStatus;
    Color statusColor;
    IconData statusIcon;

    // Handle string-based status instead of enum
    switch (status.toLowerCase()) {
      case 'normal':
        statusColor = AppTheme.successColor;
        statusIcon = Icons.check_circle;
        break;
      case 'warning':
        statusColor = AppTheme.warningColor;
        statusIcon = Icons.warning;
        break;
      case 'critical':
      case 'alert':
        statusColor = AppTheme.errorColor;
        statusIcon = Icons.error;
        break;
      case 'disconnected':
      case 'no data':
      default:
        statusColor = AppTheme.disconnectedColor;
        statusIcon = Icons.cloud_off;
        break;
    }

    return Card(
      child: Padding(
        padding: AppConstants.cardPadding,
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                statusIcon,
                color: statusColor,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    status,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: statusColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    _getSystemStatusDescription(status, viewModel),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Build alert card
  Widget _buildAlertCard(BuildContext context, String alertMessage) {
    return Card(
      color: AppTheme.errorColor.withOpacity(0.1),
      child: Padding(
        padding: AppConstants.cardPadding,
        child: Row(
          children: [
            Icon(
              Icons.warning_amber,
              color: AppTheme.errorColor,
              size: 24,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'System Alert',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: AppTheme.errorColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    alertMessage,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Build last update information
  Widget _buildLastUpdateInfo(BuildContext context, DashboardViewModel viewModel) {
    final freshness = viewModel.getDataFreshness();
    final freshnessColor = viewModel.model.lastUpdate != null
        ? AppHelpers.getDataFreshnessColor(viewModel.model.lastUpdate!)
        : AppTheme.disconnectedColor;

    return Card(
      child: Padding(
        padding: AppConstants.cardPadding,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Last Update',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: freshnessColor,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  freshness,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: freshnessColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Get battery status description
  String _getBatteryStatus(double voltage) {
    if (voltage < AppConstants.criticalBatteryLevel) return 'Critical';
    if (voltage < AppConstants.warningBatteryLevel) return 'Low';
    return 'Good';
  }

  /// Get system status description
  String _getSystemStatusDescription(String status, DashboardViewModel viewModel) {
    switch (status.toLowerCase()) {
      case 'normal':
        return 'All systems operating normally';
      case 'warning':
        return 'Some parameters need attention';
      case 'critical':
      case 'alert':
        return 'Critical issues detected';
      case 'disconnected':
      case 'no data':
      default:
        return 'No connection to monitoring system';
    }
  }
}
