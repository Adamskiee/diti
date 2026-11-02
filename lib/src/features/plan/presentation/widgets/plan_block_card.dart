import 'package:flutter/material.dart';
import 'package:diti_database/diti_database.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/duration_formatter.dart';
import '../../domain/plan_block_conflict.dart';
import 'conflict_warning_banner.dart';

/// Interactive card component representing a scheduled time block in daily planning.
///
/// Displays start and end times in tabular figures, activity title, status pill,
/// planned duration, actual duration with overrun / under stats, conflict alerts,
/// and contextual action buttons.
class PlanBlockCard extends StatelessWidget {
  final PlanBlock block;
  final List<PlanBlockConflict> conflicts;
  final VoidCallback onStart;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback? onRecordPastSession;

  const PlanBlockCard({
    super.key,
    required this.block,
    this.conflicts = const [],
    required this.onStart,
    required this.onEdit,
    required this.onDelete,
    this.onRecordPastSession,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final startLocal = block.scheduledStartUtc.toLocal();
    final endLocal =
        startLocal.add(Duration(milliseconds: block.plannedDurationMs));
    final timeFormat = DateFormat.jm();

    final title = block.routineId?.isNotEmpty == true
        ? block.routineId!
        : 'Custom Activity';
    final plannedSummary =
        DurationFormatter.formatDurationSummary(block.plannedDurationMs);

    final isInProgress = block.status == PlanBlockStatus.inProgress;
    final isScheduled = block.status == PlanBlockStatus.scheduled;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Time Column
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      timeFormat.format(startLocal),
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      timeFormat.format(endLocal),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 16),
                // Title and Details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              title,
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          _buildStatusChip(context),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Planned: $plannedSummary',
                        style: theme.textTheme.bodySmall,
                      ),
                      if (block.actualDurationMs != null) ...[
                        const SizedBox(height: 4),
                        _buildActualDurationSummary(context),
                      ],
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert),
                  onSelected: (val) {
                    if (val == 'edit') onEdit();
                    if (val == 'delete') onDelete();
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(value: 'edit', child: Text('Edit')),
                    const PopupMenuItem(
                      value: 'delete',
                      child:
                          Text('Delete', style: TextStyle(color: Colors.red)),
                    ),
                  ],
                ),
              ],
            ),
            // Conflict Banners
            for (final conflict in conflicts)
              ConflictWarningBanner(description: conflict.description),
            // Actions
            if (isScheduled) ...[
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (onRecordPastSession != null) ...[
                    IconButton(
                      icon: const Icon(Icons.history),
                      tooltip: 'Record Past Session',
                      onPressed: onRecordPastSession,
                    ),
                    const SizedBox(width: 8),
                  ],
                  FilledButton.icon(
                    onPressed: onStart,
                    icon: const Icon(Icons.play_arrow),
                    label: const Text('Start Block'),
                  ),
                ],
              ),
            ] else if (isInProgress) ...[
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerRight,
                child: FilledButton.tonalIcon(
                  onPressed: onStart,
                  icon: const Icon(Icons.timer),
                  label: const Text('View Active Timer'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatusChip(BuildContext context) {
    return switch (block.status) {
      PlanBlockStatus.scheduled => const Chip(
          label: Text('Scheduled'),
          visualDensity: VisualDensity.compact,
        ),
      PlanBlockStatus.inProgress => const Chip(
          avatar: Icon(
            Icons.play_circle_fill,
            size: 14,
            color: AppColors.awaitingActionPulse,
          ),
          label: Text('In Progress'),
          visualDensity: VisualDensity.compact,
        ),
      PlanBlockStatus.completed => const Chip(
          avatar: Icon(
            Icons.check_circle,
            size: 14,
            color: AppColors.successGreen,
          ),
          label: Text('Completed'),
          visualDensity: VisualDensity.compact,
        ),
      PlanBlockStatus.cancelled => const Chip(
          avatar: Icon(
            Icons.cancel,
            size: 14,
            color: Colors.grey,
          ),
          label: Text('Cancelled'),
          visualDensity: VisualDensity.compact,
        ),
    };
  }

  Widget _buildActualDurationSummary(BuildContext context) {
    final actualMs = block.actualDurationMs!;
    final actualText = DurationFormatter.formatDurationSummary(actualMs);
    final diffMs = actualMs - block.plannedDurationMs;

    final String diffTag;
    final Color diffColor;
    if (diffMs > 60000) {
      final overrun = DurationFormatter.formatDurationSummary(diffMs);
      diffTag = '+$overrun overrun';
      diffColor = AppColors.pausedAmber;
    } else if (diffMs < -60000) {
      final under = DurationFormatter.formatDurationSummary(-diffMs);
      diffTag = '$under under';
      diffColor = AppColors.successGreen;
    } else {
      diffTag = 'on target';
      diffColor = AppColors.successGreen;
    }

    return Row(
      children: [
        Text('Actual: $actualText ', style: const TextStyle(fontSize: 12)),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: diffColor.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            diffTag,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: diffColor,
            ),
          ),
        ),
      ],
    );
  }
}
