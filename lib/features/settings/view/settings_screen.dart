import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/utils/app_theme.dart';
import '../../../core/utils/helpers.dart';
import '../../../core/utils/constants.dart';
import '../viewmodel/settings_viewmodel.dart';
import '../widgets/connection_settings_card.dart';
import '../widgets/threshold_settings_card.dart';
import '../widgets/connection_test_card.dart';
import '../widgets/data_management_card.dart';

/// Settings screen for configuring ESP connection and thresholds
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        actions: [
          Consumer<SettingsViewModel>(
            builder: (context, viewModel, child) {
              if (!viewModel.hasUnsavedChanges) return const SizedBox.shrink();

              return Row(
                children: [
                  TextButton(
                    onPressed: viewModel.discardChanges,
                    child: const Text(
                      'Discard',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                  const SizedBox(width: 8),
                  TextButton(
                    onPressed: viewModel.isValid
                        ? () => _saveSettings(context, viewModel)
                        : null,
                    child: const Text(
                      'Save',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
              );
            },
          ),
        ],
      ),
      body: Consumer<SettingsViewModel>(
        builder: (context, viewModel, child) {
          return SingleChildScrollView(
            padding: AppConstants.defaultPadding,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Unsaved changes warning
                if (viewModel.hasUnsavedChanges)
                  _buildUnsavedChangesWarning(context),

                // Connection Settings
                ConnectionSettingsCard(viewModel: viewModel),
                const SizedBox(height: 16),

                // Threshold Settings
                ThresholdSettingsCard(viewModel: viewModel),
                const SizedBox(height: 16),

                // Connection Test
                ConnectionTestCard(viewModel: viewModel),
                const SizedBox(height: 16),

                // Data Management
                DataManagementCard(viewModel: viewModel),
                const SizedBox(height: 16),

                // Settings Summary
                _buildSettingsSummary(context, viewModel),

                // Validation Errors
                if (!viewModel.isValid)
                  _buildValidationErrors(context, viewModel),
              ],
            ),
          );
        },
      ),
      floatingActionButton: Consumer<SettingsViewModel>(
        builder: (context, viewModel, child) {
          if (!viewModel.hasUnsavedChanges || !viewModel.isValid) {
            return const SizedBox.shrink();
          }

          return FloatingActionButton.extended(
            onPressed: () => _saveSettings(context, viewModel),
            icon: const Icon(Icons.save),
            label: const Text('Save Settings'),
          );
        },
      ),
    );
  }

  /// Build unsaved changes warning
  Widget _buildUnsavedChangesWarning(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.warningColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: AppTheme.warningColor.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.warning_amber,
            color: AppTheme.warningColor,
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'You have unsaved changes. Save or discard them.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppTheme.warningColor,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Build settings summary
  Widget _buildSettingsSummary(BuildContext context, SettingsViewModel viewModel) {
    final summary = viewModel.getSettingsSummary();

    return Card(
      child: Padding(
        padding: AppConstants.cardPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.summarize,
                  color: AppTheme.primaryColor,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'Settings Summary',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            ...summary.entries.map((entry) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: Text(
                        entry.key,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 3,
                      child: Text(
                        entry.value.toString(),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  /// Build validation errors
  Widget _buildValidationErrors(BuildContext context, SettingsViewModel viewModel) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.errorColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: AppTheme.errorColor.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.error_outline,
                color: AppTheme.errorColor,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Validation Errors',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: AppTheme.errorColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          ...viewModel.validationErrors.map((error) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '• ',
                    style: TextStyle(color: AppTheme.errorColor),
                  ),
                  Expanded(
                    child: Text(
                      error,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.errorColor,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  /// Save settings
  Future<void> _saveSettings(BuildContext context, SettingsViewModel viewModel) async {
    if (!viewModel.isValid) {
      AppHelpers.showErrorSnackBar(context, 'Please fix validation errors first');
      return;
    }

    final success = await viewModel.saveSettings();

    if (context.mounted) {
      if (success) {
        AppHelpers.showSuccessSnackBar(context, 'Settings saved successfully');
      } else {
        AppHelpers.showErrorSnackBar(context, 'Failed to save settings');
      }
    }
  }
}
