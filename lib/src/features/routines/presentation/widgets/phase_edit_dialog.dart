import 'package:flutter/material.dart' hide RepeatMode;
import 'package:timer_engine/timer_engine.dart';
import 'package:uuid/uuid.dart';

class PhaseEditDialog extends StatefulWidget {
  final RoutinePhase? phase;

  const PhaseEditDialog({super.key, this.phase});

  @override
  State<PhaseEditDialog> createState() => _PhaseEditDialogState();
}

class _PhaseEditDialogState extends State<PhaseEditDialog> {
  late final TextEditingController _nameController;
  late bool _isOpenEnded;
  late int _minutes;
  late TransitionPolicy _transition;
  late PhaseKind _kind;
  bool _kindTouched = false;

  @override
  void initState() {
    super.initState();
    final p = widget.phase;
    _nameController = TextEditingController(text: p?.name ?? 'Focus');
    _isOpenEnded = p != null && p.durationMs == null;
    _minutes = p?.durationMs != null ? (p!.durationMs! ~/ 60000) : 25;
    if (_minutes <= 0) _minutes = 1;
    _transition = p?.transition ?? TransitionPolicy.auto;
    // A new phase starts out with the kind its name suggests. An existing
    // phase keeps the kind it was stored with: the name heuristic only seeds
    // a new phase, it never reclassifies one the user already tagged.
    _kind = p?.kind ?? PhaseKind.inferFromName(_nameController.text);
    _nameController.addListener(_onNameChanged);
  }

  /// Keeps the kind of a new phase in step with its name, until the user
  /// picks a kind themselves.
  void _onNameChanged() {
    if (_kindTouched || widget.phase != null) return;
    final inferred = PhaseKind.inferFromName(_nameController.text);
    if (inferred == _kind) return;
    setState(() => _kind = inferred);
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AlertDialog(
      title: Text(widget.phase == null ? 'Add Phase' : 'Edit Phase'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              key: const Key('phase_name_field'),
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Phase Name'),
            ),
            const SizedBox(height: 16),
            Text(
              'Kind',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            SegmentedButton<PhaseKind>(
              // Each segment wears the colour its kind carries in the rest of
              // the app, so the toggle previews it: focus is the primary
              // colour, rest the tertiary one.
              segments: [
                ButtonSegment<PhaseKind>(
                  value: PhaseKind.focus,
                  label: Text(
                    'Focus',
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ),
                ButtonSegment<PhaseKind>(
                  value: PhaseKind.rest,
                  label: Text(
                    'Rest',
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: theme.colorScheme.tertiary,
                    ),
                  ),
                ),
              ],
              selected: {_kind},
              onSelectionChanged: (val) {
                setState(() {
                  _kind = val.first;
                  _kindTouched = true;
                });
              },
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              title: const Text('Open-ended (No time limit)'),
              value: _isOpenEnded,
              onChanged: (val) {
                setState(() {
                  _isOpenEnded = val;
                  if (_isOpenEnded) {
                    _transition = TransitionPolicy.manual;
                  }
                });
              },
            ),
            if (!_isOpenEnded) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  const Text('Duration: '),
                  Text(
                    '$_minutes min',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.remove),
                    onPressed:
                        _minutes > 1 ? () => setState(() => _minutes--) : null,
                  ),
                  IconButton(
                    icon: const Icon(Icons.add),
                    onPressed: () => setState(() => _minutes++),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<TransitionPolicy>(
                initialValue: _transition,
                decoration: const InputDecoration(labelText: 'At Boundary'),
                items: const [
                  DropdownMenuItem<TransitionPolicy>(
                    value: TransitionPolicy.auto,
                    child: Text('Auto-advance to next phase'),
                  ),
                  DropdownMenuItem<TransitionPolicy>(
                    value: TransitionPolicy.manual,
                    child: Text('Wait for confirmation (Manual)'),
                  ),
                ],
                onChanged: (val) {
                  if (val != null) setState(() => _transition = val);
                },
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () {
            final name = _nameController.text.trim();
            if (name.isEmpty) return;
            final phase = RoutinePhase(
              id: widget.phase?.id ?? const Uuid().v4(),
              name: name,
              durationMs: _isOpenEnded ? null : _minutes * 60000,
              transition: _isOpenEnded ? TransitionPolicy.manual : _transition,
              kind: _kind,
            );
            Navigator.pop(context, phase);
          },
          child: const Text('Done'),
        ),
      ],
    );
  }
}
