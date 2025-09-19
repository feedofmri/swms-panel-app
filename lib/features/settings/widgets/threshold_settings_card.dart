import 'package:flutter/material.dart';
import '../../../core/utils/app_theme.dart';
import '../../../core/utils/constants.dart';
import '../viewmodel/settings_viewmodel.dart';

/// Threshold settings card for configuring alert thresholds
class ThresholdSettingsCard extends StatelessWidget {
  final SettingsViewModel viewModel;

  const ThresholdSettingsCard({
    super.key,
    required this.viewModel,
  });

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
                  Icons.tune,
                  color: AppTheme.primaryColor,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'Alert Thresholds',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Reservoir minimum level
            _buildSliderSetting(
              context,
              title: 'Reservoir Minimum Level',
              subtitle: 'Alert when reservoir drops below this level',
              value: viewModel.reservoirMinLevel,
              min: 5.0,
              max: 50.0,
              divisions: 45,
              unit: '%',
              onChanged: viewModel.updateReservoirMinLevel,
            ),

            const SizedBox(height: 20),

            // Turbidity maximum
            _buildSliderSetting(
              context,
              title: 'Turbidity Maximum',
              subtitle: 'Alert when water turbidity exceeds this value',
              value: viewModel.turbidityMax,
              min: 5.0,
              max: 50.0,
              divisions: 45,
              unit: ' NTU',
              onChanged: viewModel.updateTurbidityMax,
            ),

            const SizedBox(height: 16),

            // Reset to defaults button
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: viewModel.resetToDefaults,
                icon: const Icon(Icons.restore),
                label: const Text('Reset to Defaults'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Build slider setting widget
  Widget _buildSliderSetting(
    BuildContext context, {
    required String title,
    required String subtitle,
    required double value,
    required double min,
    required double max,
    required int divisions,
    required String unit,
    required ValueChanged<double> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: AppTheme.textSecondary,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: Slider(
                value: value,
                min: min,
                max: max,
                divisions: divisions,
                label: '${value.toStringAsFixed(1)}$unit',
                onChanged: onChanged,
              ),
            ),
            const SizedBox(width: 12),
            Container(
              width: 80,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                '${value.toStringAsFixed(1)}$unit',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppTheme.primaryColor,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
