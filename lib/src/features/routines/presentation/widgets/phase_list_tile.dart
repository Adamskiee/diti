import 'package:flutter/material.dart' hide RepeatMode;
import 'package:timer_engine/timer_engine.dart';
import '../../../../core/utils/duration_formatter.dart';

class PhaseListTile extends StatelessWidget {
  final RoutinePhase phase;
  final int? index;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const PhaseListTile({
    super.key,
    required this.phase,
    this.index,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    Widget leading = const Icon(Icons.drag_handle);
    if (index != null) {
      leading = ReorderableDragStartListener(
        index: index!,
        child: leading,
      );
    }

    return ListTile(
      key: key ?? ValueKey(phase.id),
      leading: leading,
      title: Text(phase.name),
      subtitle: Row(
        children: [
          Flexible(
            child: Text(
              '${DurationFormatter.formatDurationSummary(phase.durationMs)} · ${phase.transition == TransitionPolicy.auto ? "Auto" : "Manual"}',
            ),
          ),
          const SizedBox(width: 8),
          _kindChip(theme),
        ],
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.edit, size: 20),
            tooltip: 'Edit Phase',
            onPressed: onEdit,
          ),
          IconButton(
            icon: const Icon(Icons.delete, size: 20, color: Colors.red),
            tooltip: 'Delete Phase',
            onPressed: onDelete,
          ),
        ],
      ),
    );
  }

  /// The kind of the phase, as a chip next to the phase's details. Focus
  /// wears the primary colour and rest the tertiary one - the convention the
  /// rest of the app uses for the two kinds.
  Widget _kindChip(ThemeData theme) {
    final isFocus = phase.kind == PhaseKind.focus;
    final kindColor =
        isFocus ? theme.colorScheme.primary : theme.colorScheme.tertiary;

    return Chip(
      label: Text(
        isFocus ? 'Focus' : 'Rest',
        style: theme.textTheme.labelSmall?.copyWith(
          color: kindColor,
          fontWeight: FontWeight.w600,
        ),
      ),
      backgroundColor: kindColor.withAlpha(30),
      padding: EdgeInsets.zero,
      labelPadding: const EdgeInsets.symmetric(horizontal: 8),
      visualDensity: VisualDensity.compact,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }
}
