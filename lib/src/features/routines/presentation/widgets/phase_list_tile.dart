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
      subtitle: Text(
        '${DurationFormatter.formatDurationSummary(phase.durationMs)} · ${phase.transition == TransitionPolicy.auto ? "Auto" : "Manual"}',
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
}
