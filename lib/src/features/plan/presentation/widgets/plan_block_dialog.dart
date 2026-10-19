import 'package:flutter/material.dart' hide RepeatMode;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:diti_database/diti_database.dart';
import 'package:intl/intl.dart';
import 'package:timer_engine/timer_engine.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/di/repositories_provider.dart';
import '../../../../core/utils/duration_formatter.dart';
import '../../domain/plan_block_conflict.dart';
import '../../providers/plan_providers.dart';
import 'conflict_warning_banner.dart';

/// Modal dialog for scheduling a new plan block or editing an existing one.
///
/// Supports selecting a routine from available routines or creating a custom activity,
/// picking start times, stepping duration in 5-minute increments, and previewing
/// conflicts in real time against the daily schedule.
class PlanBlockDialog extends ConsumerStatefulWidget {
  final String planDate;
  final DateTime initialStartUtc;
  final PlanBlock? existingBlock;

  const PlanBlockDialog({
    super.key,
    required this.planDate,
    required this.initialStartUtc,
    this.existingBlock,
  });

  @override
  ConsumerState<PlanBlockDialog> createState() => _PlanBlockDialogState();
}

enum _PlanSourceType { routine, custom }

class _PlanBlockDialogState extends ConsumerState<PlanBlockDialog> {
  _PlanSourceType _sourceType = _PlanSourceType.routine;
  final _titleController = TextEditingController();
  List<Routine> _availableRoutines = [];
  String? _selectedRoutineId;
  late DateTime _scheduledStartUtc;
  late int _durationMinutes;
  List<PlanBlockConflict> _conflicts = [];
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _scheduledStartUtc =
        widget.existingBlock?.scheduledStartUtc ?? widget.initialStartUtc;
    _durationMinutes = widget.existingBlock != null
        ? (widget.existingBlock!.plannedDurationMs ~/ 60000)
        : 50;

    _loadRoutines();
  }

  Future<void> _loadRoutines() async {
    final routines = await ref.read(routineRepositoryProvider).getAllRoutines();
    if (!mounted) return;

    setState(() {
      _availableRoutines = routines;
      if (widget.existingBlock != null) {
        final existingTitle = widget.existingBlock!.routineId ?? '';
        final routineMatches = routines.any((r) => r.name == existingTitle);
        if (routineMatches) {
          _sourceType = _PlanSourceType.routine;
          _selectedRoutineId = existingTitle;
        } else {
          _sourceType = _PlanSourceType.custom;
          _titleController.text = existingTitle;
          if (routines.isNotEmpty) {
            _selectedRoutineId = routines.first.name;
          }
        }
      } else {
        if (routines.isNotEmpty) {
          _selectedRoutineId = routines.first.name;
          _applyRoutineDuration(routines.first);
        } else {
          _sourceType = _PlanSourceType.custom;
        }
      }
    });

    _evaluateConflicts();
  }

  void _applyRoutineDuration(Routine routine) {
    int totalMs = 0;
    for (final p in routine.phases) {
      if (p.durationMs != null) totalMs += p.durationMs!;
    }
    if (routine.repeatRule.mode == RepeatMode.count) {
      totalMs *= routine.repeatRule.count;
    }
    if (totalMs > 0) {
      _durationMinutes = totalMs ~/ 60000;
      if (_durationMinutes <= 0) {
        _durationMinutes = 1;
      }
    }
  }

  void _evaluateConflicts() {
    final controller = ref.read(dailyPlanControllerProvider.notifier);
    final conflicts = controller.checkTentativeConflict(
      startUtc: _scheduledStartUtc,
      durationMs: _durationMinutes * 60000,
      excludeBlockId: widget.existingBlock?.id,
    );
    setState(() => _conflicts = conflicts);
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  Future<void> _pickTime() async {
    final local = _scheduledStartUtc.toLocal();
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: local.hour, minute: local.minute),
    );
    if (picked != null) {
      final updatedLocal = DateTime(
        local.year,
        local.month,
        local.day,
        picked.hour,
        picked.minute,
      );
      setState(() {
        _scheduledStartUtc = updatedLocal.toUtc();
      });
      _evaluateConflicts();
    }
  }

  void _save() {
    final title = _sourceType == _PlanSourceType.routine
        ? _selectedRoutineId
        : _titleController.text.trim();

    if (title == null || title.isEmpty) {
      setState(() => _errorMessage = 'Activity title is required');
      return;
    }
    if (_durationMinutes <= 0) {
      setState(() => _errorMessage = 'Duration must be greater than 0');
      return;
    }

    final block = PlanBlock(
      id: widget.existingBlock?.id ?? const Uuid().v4(),
      planDate: widget.planDate,
      scheduledStartUtc: _scheduledStartUtc,
      timezoneId: DateTime.now().timeZoneName,
      plannedDurationMs: _durationMinutes * 60000,
      routineId: title,
      status: widget.existingBlock?.status ?? PlanBlockStatus.scheduled,
      actualDurationMs: widget.existingBlock?.actualDurationMs,
      sessionId: widget.existingBlock?.sessionId,
    );

    Navigator.of(context).pop(block);
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(dailyPlanControllerProvider, (_, __) => _evaluateConflicts());

    final theme = Theme.of(context);
    final startLocal = _scheduledStartUtc.toLocal();
    final endLocal = startLocal.add(Duration(minutes: _durationMinutes));
    final timeFormat = DateFormat.jm();

    return AlertDialog(
      title:
          Text(widget.existingBlock == null ? 'Schedule Block' : 'Edit Block'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_errorMessage != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  _errorMessage!,
                  style: const TextStyle(color: Colors.red),
                ),
              ),
            SegmentedButton<_PlanSourceType>(
              segments: const [
                ButtonSegment(
                  value: _PlanSourceType.routine,
                  label: Text('From Routine'),
                ),
                ButtonSegment(
                  value: _PlanSourceType.custom,
                  label: Text('Custom Activity'),
                ),
              ],
              selected: {_sourceType},
              onSelectionChanged: (val) {
                setState(() => _sourceType = val.first);
                _evaluateConflicts();
              },
            ),
            const SizedBox(height: 16),
            if (_sourceType == _PlanSourceType.routine) ...[
              DropdownButtonFormField<String>(
                key: ValueKey(_selectedRoutineId),
                initialValue: _selectedRoutineId,
                decoration: const InputDecoration(
                  labelText: 'Select Routine',
                  border: OutlineInputBorder(),
                ),
                items: [
                  for (final r in _availableRoutines)
                    DropdownMenuItem(value: r.name, child: Text(r.name)),
                ],
                onChanged: (val) {
                  if (val != null) {
                    setState(() => _selectedRoutineId = val);
                    final routine =
                        _availableRoutines.firstWhere((r) => r.name == val);
                    _applyRoutineDuration(routine);
                    _evaluateConflicts();
                  }
                },
              ),
            ] else ...[
              TextField(
                key: const Key('plan_title_field'),
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Activity Name',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
            const SizedBox(height: 16),
            // Start Time Row
            Row(
              children: [
                const Text(
                  'Start Time: ',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                OutlinedButton.icon(
                  onPressed: _pickTime,
                  icon: const Icon(Icons.access_time),
                  label: Text(timeFormat.format(startLocal)),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Duration Stepper
            Row(
              children: [
                const Text(
                  'Duration: ',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  DurationFormatter.formatDurationSummary(
                    _durationMinutes * 60000,
                  ),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.remove),
                  onPressed: _durationMinutes > 5
                      ? () {
                          setState(() => _durationMinutes -= 5);
                          _evaluateConflicts();
                        }
                      : null,
                ),
                IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: () {
                    setState(() => _durationMinutes += 5);
                    _evaluateConflicts();
                  },
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Scheduled: ${timeFormat.format(startLocal)} → ${timeFormat.format(endLocal)}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            if (_conflicts.isNotEmpty) ...[
              const SizedBox(height: 8),
              for (final c in _conflicts)
                ConflictWarningBanner(description: c.description),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _save,
          child: const Text('Save Block'),
        ),
      ],
    );
  }
}
