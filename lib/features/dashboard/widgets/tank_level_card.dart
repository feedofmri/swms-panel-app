import 'package:flutter/material.dart';
import 'package:percent_indicator/percent_indicator.dart';
import '../../../core/utils/app_theme.dart';
import '../../../core/utils/helpers.dart';
import '../../../core/utils/constants.dart';

/// Tank level card widget with circular progress indicator
class TankLevelCard extends StatelessWidget {
  final String title;
  final double level;
  final IconData icon;
  final bool isConnected;

  const TankLevelCard({
    super.key,
    required this.title,
    required this.level,
    required this.icon,
    this.isConnected = true,
  });

  @override
  Widget build(BuildContext context) {
    final tankColor = isConnected ? AppHelpers.getTankLevelColor(level) : Colors.grey;
    final displayLevel = isConnected ? level : 0.0;
    final tankStatus = AppHelpers.getTankStatus(level);

    return Card(
      child: Padding(
        padding: AppConstants.cardPadding,
        child: Column(
          children: [
            // Header
            Row(
              children: [
                Icon(
                  icon,
                  color: isConnected ? tankColor : Colors.grey,
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

            // Circular progress indicator
            CircularPercentIndicator(
              radius: 50.0,
              lineWidth: 8.0,
              percent: displayLevel / 100,
              center: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    isConnected ? '${level.toInt()}%' : '--',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: tankColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    isConnected ? tankStatus.displayText : 'No data',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: isConnected ? AppTheme.textSecondary : Colors.grey,
                    ),
                  ),
                ],
              ),
              progressColor: tankColor,
              backgroundColor: tankColor.withOpacity(0.2),
              circularStrokeCap: CircularStrokeCap.round,
              animation: true,
              animationDuration: 1000,
            ),
            const SizedBox(height: 12),

            // Status indicator
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
              decoration: BoxDecoration(
                color: tankColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                isConnected ? _getTankStatusMessage(level) : 'Connection Lost',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: tankColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Get tank status message based on level
  String _getTankStatusMessage(double level) {
    if (level <= 10) return 'Critically Low';
    if (level <= 25) return 'Low Level';
    if (level <= 60) return 'Medium Level';
    if (level <= 85) return 'High Level';
    return 'Tank Full';
  }
}
