import 'package:flutter/material.dart';
import 'package:focus_flow_database/focus_flow_database.dart';
import 'package:intl/intl.dart';
import '../../../../core/utils/duration_formatter.dart';

class SessionFeedTile extends StatelessWidget {
  final SessionRecord session;
  final VoidCallback onTap;

  const SessionFeedTile({
    super.key,
    required this.session,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final localStart = session.startedAtUtc.toLocal();
    final localEnd = session.endedAtUtc.toLocal();
    final timeRange =
        '${DateFormat('h:mm a').format(localStart)} – ${DateFormat('h:mm a').format(localEnd)}';

    final isCompleted = session.outcome == SessionOutcome.completed;
    final outcomeColor =
        isCompleted ? const Color(0xFF006C50) : const Color(0xFFBA1A1A);
    final outcomeIcon =
        isCompleted ? Icons.check_circle_outline : Icons.cancel_outlined;

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 8),
      color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: Icon(outcomeIcon, color: outcomeColor),
        title: Text(
          session.routineName.trim().isEmpty ? 'Quick Timer' : session.routineName,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Text(
          timeRange,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            DurationFormatter.formatMs(session.totalDurationMs),
            style: theme.textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.bold,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ),
      ),
    );
  }
}
