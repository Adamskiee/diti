import 'package:flutter/material.dart' hide RepeatMode;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timer_engine/timer_engine.dart';
import 'package:uuid/uuid.dart';
import '../../../core/di/repositories_provider.dart';
import '../providers/routines_providers.dart';
import 'widgets/phase_edit_dialog.dart';
import 'widgets/phase_list_tile.dart';

class RoutineEditorScreen extends ConsumerStatefulWidget {
  final String? routineId;

  const RoutineEditorScreen({super.key, this.routineId});

  @override
  ConsumerState<RoutineEditorScreen> createState() => _RoutineEditorScreenState();
}

class _RoutineEditorScreenState extends ConsumerState<RoutineEditorScreen> {
  final _nameController = TextEditingController();
  final _phases = <RoutinePhase>[];
  RepeatMode _repeatMode = RepeatMode.count;
  int _repeatCount = 1;
  String? _errorMessage;
  late bool _isLoading;

  @override
  void initState() {
    super.initState();
    _isLoading = widget.routineId != null;
    if (widget.routineId != null) {
      _loadExisting();
    }
  }

  Future<void> _loadExisting() async {
    final repo = ref.read(routineRepositoryProvider);
    final routine = await repo.getRoutine(widget.routineId!);
    if (routine != null && mounted) {
      _nameController.text = routine.name;
      _phases.addAll(routine.phases);
      _repeatMode = routine.repeatRule.mode;
      _repeatCount = routine.repeatRule.count;
    }
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _addOrEditPhase([RoutinePhase? phase, int? index]) async {
    final result = await showDialog<RoutinePhase>(
      context: context,
      builder: (ctx) => PhaseEditDialog(phase: phase),
    );
    if (result != null && mounted) {
      setState(() {
        if (index != null) {
          _phases[index] = result;
        } else {
          _phases.add(result);
        }
      });
    }
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      setState(() => _errorMessage = 'Routine name is required');
      return;
    }
    if (_phases.isEmpty) {
      setState(() => _errorMessage = 'At least one phase is required');
      return;
    }

    setState(() => _errorMessage = null);

    final routine = Routine(
      id: widget.routineId ?? const Uuid().v4(),
      name: name,
      repeatRule: RepeatRule(mode: _repeatMode, count: _repeatCount),
      phases: List<RoutinePhase>.unmodifiable(_phases),
    );

    final validationError = routine.validate();
    if (validationError != null) {
      setState(() => _errorMessage = 'Invalid routine configuration: $validationError');
      return;
    }

    final repo = ref.read(routineRepositoryProvider);
    await repo.saveRoutine(routine);
    await ref.read(routineListControllerProvider.notifier).refresh();

    if (mounted) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.routineId == null ? 'New Routine' : 'Edit Routine'),
        actions: [
          TextButton(
            onPressed: _save,
            child: const Text('Save', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (_errorMessage != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                _errorMessage!,
                style: const TextStyle(color: Colors.red),
              ),
            ),
          TextField(
            key: const Key('routine_name_field'),
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: 'Routine Name',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Repeat Settings',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          SegmentedButton<RepeatMode>(
            segments: const [
              ButtonSegment<RepeatMode>(
                value: RepeatMode.count,
                label: Text('Count'),
              ),
              ButtonSegment<RepeatMode>(
                value: RepeatMode.forever,
                label: Text('Forever'),
              ),
            ],
            selected: {_repeatMode},
            onSelectionChanged: (val) {
              setState(() => _repeatMode = val.first);
            },
          ),
          if (_repeatMode == RepeatMode.count) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                const Text('Repeat Cycles: '),
                Text(
                  '$_repeatCount',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.remove),
                  onPressed: _repeatCount > 1
                      ? () => setState(() => _repeatCount--)
                      : null,
                ),
                IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: () => setState(() => _repeatCount++),
                ),
              ],
            ),
          ],
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Phases',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              OutlinedButton.icon(
                onPressed: () => _addOrEditPhase(),
                icon: const Icon(Icons.add),
                label: const Text('Add Phase'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ReorderableListView.builder(
            buildDefaultDragHandles: false,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _phases.length,
            onReorderItem: (oldIndex, newIndex) {
              setState(() {
                final item = _phases.removeAt(oldIndex);
                _phases.insert(newIndex, item);
              });
            },
            itemBuilder: (context, index) {
              final phase = _phases[index];
              return PhaseListTile(
                key: ValueKey(phase.id),
                phase: phase,
                index: index,
                onEdit: () => _addOrEditPhase(phase, index),
                onDelete: () => setState(() => _phases.removeAt(index)),
              );
            },
          ),
        ],
      ),
    );
  }
}
