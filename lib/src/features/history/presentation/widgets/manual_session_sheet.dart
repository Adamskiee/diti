import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/utils/duration_formatter.dart';
import '../controllers/manual_session_controller.dart';

class ManualSessionSheet extends ConsumerStatefulWidget {
  final DateTime? initialDate;
  final TimeOfDay? initialStartTime;
  final int? initialDurationMinutes;
  final String? initialRoutineName;
  final String? initialPlanBlockId;

  const ManualSessionSheet({
    super.key,
    this.initialDate,
    this.initialStartTime,
    this.initialDurationMinutes,
    this.initialRoutineName,
    this.initialPlanBlockId,
  });

  @override
  ConsumerState<ManualSessionSheet> createState() => _ManualSessionSheetState();
}

class _ManualSessionSheetState extends ConsumerState<ManualSessionSheet> {
  late final ManualSessionParams _params;
  late final TextEditingController _titleController;
  late final TextEditingController _durationController;

  @override
  void initState() {
    super.initState();
    _params = ManualSessionParams(
      initialDate: widget.initialDate,
      initialStartTime: widget.initialStartTime,
      initialDurationMinutes: widget.initialDurationMinutes,
      initialRoutineName: widget.initialRoutineName,
      initialPlanBlockId: widget.initialPlanBlockId,
    );
    ref.read(manualSessionControllerProvider(_params));
    _titleController = TextEditingController(text: widget.initialRoutineName ?? '');
    _durationController = TextEditingController(
      text: (widget.initialDurationMinutes ?? 30).toString(),
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _durationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(manualSessionControllerProvider(_params));
    final controller = ref.read(manualSessionControllerProvider(_params).notifier);
    final theme = Theme.of(context);
    final timeFormat = DateFormat.jm();
    final dateFormat = DateFormat.yMMMd();

    final startTimeLocal = DateTime(
      state.selectedDate.year,
      state.selectedDate.month,
      state.selectedDate.day,
      state.startTime.hour,
      state.startTime.minute,
    );
    final endTimeLocal = DateTime(
      state.selectedDate.year,
      state.selectedDate.month,
      state.selectedDate.day,
      state.endTime.hour,
      state.endTime.minute,
    );

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 20,
          bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Record Past Session',
                    style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (state.errorMessage != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.errorContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    state.errorMessage!,
                    style: TextStyle(color: theme.colorScheme.onErrorContainer),
                  ),
                ),
                const SizedBox(height: 12),
              ],
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Activity / Routine Name',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.fitness_center),
                ),
                onChanged: (val) => controller.setRoutineName(val),
              ),
              const SizedBox(height: 16),
              ListTile(
                shape: RoundedRectangleBorder(
                  side: BorderSide(color: theme.colorScheme.outlineVariant),
                  borderRadius: BorderRadius.circular(8),
                ),
                leading: const Icon(Icons.calendar_today),
                title: const Text('Date'),
                subtitle: Text(dateFormat.format(state.selectedDate)),
                onTap: () async {
                  final now = DateTime.now();
                  final lastDate = state.selectedDate.isAfter(now) ? state.selectedDate : now;
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: state.selectedDate,
                    firstDate: DateTime(2020),
                    lastDate: lastDate,
                  );
                  if (picked != null) controller.setDate(picked);
                },
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: ListTile(
                      shape: RoundedRectangleBorder(
                        side: BorderSide(color: theme.colorScheme.outlineVariant),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      leading: const Icon(Icons.play_arrow),
                      title: const Text('Start Time'),
                      subtitle: Text(timeFormat.format(startTimeLocal)),
                      onTap: () async {
                        final picked = await showTimePicker(
                          context: context,
                          initialTime: state.startTime,
                        );
                        if (picked != null) {
                          controller.setStartTime(picked);
                          _durationController.text =
                              ref.read(manualSessionControllerProvider(_params)).durationMinutes.toString();
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ListTile(
                      shape: RoundedRectangleBorder(
                        side: BorderSide(color: theme.colorScheme.outlineVariant),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      leading: const Icon(Icons.stop),
                      title: const Text('End Time'),
                      subtitle: Text(timeFormat.format(endTimeLocal)),
                      onTap: () async {
                        final picked = await showTimePicker(
                          context: context,
                          initialTime: state.endTime,
                        );
                        if (picked != null) {
                          controller.setEndTime(picked);
                          _durationController.text =
                              ref.read(manualSessionControllerProvider(_params)).durationMinutes.toString();
                        }
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _durationController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Duration (minutes)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.timer),
                ),
                onChanged: (val) {
                  final min = int.tryParse(val);
                  if (min != null && min > 0) {
                    controller.setDurationMinutes(min);
                  }
                },
              ),
              const SizedBox(height: 16),
              Text(
                'Detected Application Activity',
                style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              if (state.isLoadingUsage)
                const Center(child: CircularProgressIndicator())
              else if (state.detectedAppUsages.isEmpty)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text('No background application activity detected in this time range.'),
                )
              else
                Card(
                  child: ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: state.detectedAppUsages.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (ctx, idx) {
                      final app = state.detectedAppUsages[idx];
                      return ListTile(
                        dense: true,
                        title: Text(app.appName, style: const TextStyle(fontWeight: FontWeight.w600)),
                        subtitle: Text(app.category),
                        trailing: Text(
                          DurationFormatter.formatDurationSummary(app.durationMs),
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      );
                    },
                  ),
                ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 12),
                  FilledButton(
                    onPressed: state.isSaving
                        ? null
                        : () async {
                            final success = await controller.saveSession();
                            if (success && context.mounted) {
                              Navigator.of(context).pop();
                            }
                          },
                    child: state.isSaving
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Save Session'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
