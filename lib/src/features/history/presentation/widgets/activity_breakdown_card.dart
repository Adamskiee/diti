import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:diti_database/diti_database.dart';
import 'package:intl/intl.dart';
import '../../../../core/utils/duration_formatter.dart';
import '../../domain/analytics_models.dart';
import 'session_detail_sheet.dart';

class ActivityBreakdownCard extends StatelessWidget {
  final List<ActivityBreakdown> breakdowns;

  const ActivityBreakdownCard({
    super.key,
    required this.breakdowns,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (breakdowns.isEmpty) {
      return const SizedBox.shrink();
    }

    return Card(
      elevation: 0,
      color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Activity Breakdown',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: SizedBox(
                height: 12,
                child: Row(
                  children: breakdowns.map((b) {
                    return Expanded(
                      flex: math.max(1, (b.percentage * 1000).toInt()),
                      child: Container(color: b.color),
                    );
                  }).toList(),
                ),
              ),
            ),
            const SizedBox(height: 8),
            ...breakdowns.map((b) {
              final pct = (b.percentage * 100).toInt();
              return Theme(
                data: theme.copyWith(dividerColor: Colors.transparent),
                child: ExpansionTile(
                  key: Key('activity_breakdown_${b.routineName}'),
                  tilePadding: const EdgeInsets.symmetric(horizontal: 4.0),
                  childrenPadding:
                      const EdgeInsets.only(left: 8.0, right: 8.0, bottom: 8.0),
                  shape: const Border(),
                  collapsedShape: const Border(),
                  leading: Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: b.color,
                      shape: BoxShape.circle,
                    ),
                  ),
                  title: Text(
                    '${b.routineName} ($pct% · ${DurationFormatter.formatMs(b.totalDurationMs)})',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                  subtitle: Text(
                    '${b.sessions.length} session${b.sessions.length == 1 ? '' : 's'}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  children: [
                    if (b.sessions.isEmpty)
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text(
                          'No session details available',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.outline,
                          ),
                        ),
                      )
                    else
                      ...b.sessions
                          .map((s) => _BreakdownSessionTile(session: s)),
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

class _BreakdownSessionTile extends StatelessWidget {
  final SessionRecord session;

  const _BreakdownSessionTile({required this.session});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isCompleted = session.outcome == SessionOutcome.completed;
    final outcomeColor =
        isCompleted ? const Color(0xFF006C50) : const Color(0xFFBA1A1A);
    final outcomeIcon =
        isCompleted ? Icons.check_circle_outline : Icons.cancel_outlined;

    final localStart = session.startedAtUtc.toLocal();
    final localEnd = session.endedAtUtc.toLocal();
    final dateStr = DateFormat('MMM d').format(localStart);
    final timeRangeStr =
        '${DateFormat('h:mm a').format(localStart)} – ${DateFormat('h:mm a').format(localEnd)}';

    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: () {
        showModalBottomSheet<void>(
          context: context,
          isScrollControlled: true,
          builder: (_) => SessionDetailSheet(session: session),
        );
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
        child: Row(
          children: [
            Icon(
              outcomeIcon,
              color: outcomeColor,
              size: 18,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    dateStr,
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    timeRangeStr,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                DurationFormatter.formatMs(session.totalDurationMs),
                style: theme.textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
