import 'package:flutter/material.dart';
import '../../../../core/theme/responsive_layout.dart';
import '../../../../core/utils/duration_formatter.dart';
import '../../domain/analytics_models.dart';

class SummaryMetricCards extends StatelessWidget {
  final AnalyticsSummary summary;

  const SummaryMetricCards({
    super.key,
    required this.summary,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final completionPct = (summary.completionRate * 100).toInt();

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= ResponsiveBreakpoints.expanded;

        final totalTile = _buildMetricTile(
          context,
          icon: Icons.timer_outlined,
          label: 'Total',
          value: DurationFormatter.formatMs(summary.totalDurationMs),
          color: theme.colorScheme.secondary,
        );

        final focusTile = _buildMetricTile(
          context,
          icon: Icons.bolt_outlined,
          label: 'Focus',
          value: DurationFormatter.formatMs(summary.focusDurationMs),
          color: theme.colorScheme.primary,
        );

        final restTile = _buildMetricTile(
          context,
          icon: Icons.self_improvement_outlined,
          label: 'Rest',
          value: DurationFormatter.formatMs(summary.restDurationMs),
          color: theme.colorScheme.tertiary,
        );

        final completedTile = _buildMetricTile(
          context,
          icon: Icons.check_circle_outline,
          label: 'Completed',
          value: '${summary.completedCount} ($completionPct%)',
          color: const Color(0xFF006C50),
        );

        if (isWide) {
          return Row(
            children: [
              Expanded(child: totalTile),
              const SizedBox(width: 12),
              Expanded(child: focusTile),
              const SizedBox(width: 12),
              Expanded(child: restTile),
              const SizedBox(width: 12),
              Expanded(child: completedTile),
            ],
          );
        }

        return Column(
          children: [
            Row(
              children: [
                Expanded(child: totalTile),
                const SizedBox(width: 12),
                Expanded(child: focusTile),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: restTile),
                const SizedBox(width: 12),
                Expanded(child: completedTile),
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _buildMetricTile(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    final theme = Theme.of(context);

    return Card(
      elevation: 0,
      color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 18, color: color),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    label,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
