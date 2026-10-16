import 'package:flutter/material.dart' hide RepeatMode;
import 'package:timer_engine/timer_engine.dart';
import '../../../../core/utils/duration_formatter.dart';

class RoutineCard extends StatelessWidget {
  final Routine routine;
  final VoidCallback onStart;
  final VoidCallback onTap;
  final VoidCallback onDuplicate;
  final VoidCallback onDelete;

  const RoutineCard({
    super.key,
    required this.routine,
    required this.onStart,
    required this.onTap,
    required this.onDuplicate,
    required this.onDelete,
  });

  int? get totalDurationMs {
    int sum = 0;
    for (final p in routine.phases) {
      if (p.durationMs == null) return null;
      sum += p.durationMs!;
    }
    if (routine.repeatRule.mode == RepeatMode.count) {
      sum *= routine.repeatRule.count;
    }
    return sum;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final durationText = DurationFormatter.formatDurationSummary(totalDurationMs);

    final repeatLabel = switch (routine.repeatRule.mode) {
      RepeatMode.count when routine.repeatRule.count == 1 => 'Once',
      RepeatMode.count => 'x${routine.repeatRule.count}',
      RepeatMode.forever => '∞',
    };

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      routine.name,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Chip(
                    label: Text(durationText),
                    visualDensity: VisualDensity.compact,
                  ),
                  const SizedBox(width: 4),
                  PopupMenuButton<String>(
                    key: Key('routine_overflow_${routine.id}'),
                    icon: const Icon(Icons.more_vert),
                    onSelected: (value) {
                      if (value == 'duplicate') onDuplicate();
                      if (value == 'delete') onDelete();
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'duplicate',
                        child: Text('Duplicate'),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Text('Delete', style: TextStyle(color: Colors.red)),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: [
                  for (final phase in routine.phases)
                    Chip(
                      label: Text(
                        '${phase.name} (${DurationFormatter.formatDurationSummary(phase.durationMs)})',
                        style: theme.textTheme.bodySmall,
                      ),
                      visualDensity: VisualDensity.compact,
                    ),
                  Chip(
                    avatar: const Icon(Icons.repeat, size: 14),
                    label: Text(repeatLabel, style: theme.textTheme.bodySmall),
                    visualDensity: VisualDensity.compact,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerRight,
                child: FilledButton.icon(
                  onPressed: onStart,
                  icon: const Icon(Icons.play_arrow),
                  label: const Text('Start'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
