import 'package:flutter/material.dart';
import 'package:diti_tracker/diti_tracker.dart';
import '../../../../core/utils/duration_formatter.dart';

class SessionAppBreakdownCard extends StatelessWidget {
  final List<AppUsageSummary> usages;
  final int totalDurationMs;

  const SessionAppBreakdownCard({
    super.key,
    required this.usages,
    required this.totalDurationMs,
  });

  IconData _iconForCategory(String category) {
    switch (category.toLowerCase()) {
      case 'terminal':
        return Icons.terminal;
      case 'youtube':
        return Icons.play_circle_fill;
      case 'development':
        return Icons.code;
      case 'browser':
        return Icons.public;
      case 'productivity':
        return Icons.edit_note;
      default:
        return Icons.apps;
    }
  }

  Color _colorForCategory(BuildContext context, String category) {
    final theme = Theme.of(context);
    switch (category.toLowerCase()) {
      case 'terminal':
        return Colors.green;
      case 'youtube':
        return Colors.red;
      case 'development':
        return Colors.blue;
      case 'browser':
        return Colors.orange;
      case 'productivity':
        return Colors.purple;
      default:
        return theme.colorScheme.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (usages.isEmpty) return const SizedBox.shrink();

    final theme = Theme.of(context);

    return Card(
      elevation: 0,
      color: theme.colorScheme.surfaceContainerHighest.withAlpha(80),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.pie_chart_outline,
                  size: 20,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 8),
                Text(
                  'Tracked Activity',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...usages.map((usage) {
              final pct = totalDurationMs > 0
                  ? (usage.durationMs / totalDurationMs).clamp(0.0, 1.0)
                  : 0.0;
              final color = _colorForCategory(context, usage.category);
              final displayName =
                  usage.category.toLowerCase() == 'youtube' ? 'YouTube' : usage.appName;

              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          _iconForCategory(usage.category),
                          size: 16,
                          color: color,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            displayName,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        Text(
                          DurationFormatter.formatMs(usage.durationMs),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                            fontFeatures: const [FontFeature.tabularFigures()],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: pct,
                        minHeight: 4,
                        color: color,
                        backgroundColor: color.withAlpha(40),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}
