import 'package:flutter/material.dart';
import 'package:diti_database/diti_database.dart';
import 'package:intl/intl.dart';
import 'package:timer_engine/timer_engine.dart';
import '../../../../core/utils/duration_formatter.dart';
import '../../domain/session_split.dart';

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

    final split = _buildFocusRestSplit(theme);

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 8),
      color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            onTap: onTap,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            leading: Icon(outcomeIcon, color: outcomeColor),
            title: Text(
              session.routineName.trim().isEmpty
                  ? 'Quick Timer'
                  : session.routineName,
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
          if (split != null)
            // The split is its own row under the total rather than part of
            // the trailing column: in the trailing column it would take the
            // width the routine name needs and wrap it on a narrow screen.
            // It opens the same sheet as the tile.
            InkWell(
              onTap: onTap,
              child: Padding(
                padding: const EdgeInsets.only(right: 16, bottom: 8),
                child: Align(
                  alignment: Alignment.centerRight,
                  child: split,
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// The session's focus and rest time, as a compact line under the total.
  ///
  /// The split comes from the phase events the session recorded, so a phase
  /// that was renamed after the session keeps the kind it was recorded with.
  /// There is nothing to split when the session recorded no rest time at all
  /// - and a session recorded before the per-phase breakdown existed has no
  /// events at all, so it shows its total alone.
  Widget? _buildFocusRestSplit(ThemeData theme) {
    final split = splitSessionByKind(session.events);
    if (split == null) return null;
    // A session that recorded no rest phase has no split worth showing.
    if (!session.events.any((event) => event.kind == PhaseKind.rest)) {
      return null;
    }

    return Text.rich(
      TextSpan(
        children: [
          TextSpan(
            text: '${DurationFormatter.formatMs(split.focusMs)} focus',
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.primary,
            ),
          ),
          const TextSpan(text: ' · '),
          TextSpan(
            text: '${DurationFormatter.formatMs(split.restMs)} rest',
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.tertiary,
            ),
          ),
        ],
      ),
      style: theme.textTheme.labelSmall?.copyWith(
        fontFeatures: const [FontFeature.tabularFigures()],
      ),
      textAlign: TextAlign.end,
    );
  }
}
