import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:diti_database/diti_database.dart';
import '../../../core/di/timer_engine_provider.dart';
import '../../timer/controllers/active_timer_controller.dart';
import '../../timer/presentation/active_timer_screen.dart';
import '../providers/plan_providers.dart';
import 'widgets/date_selector_strip.dart';
import 'widgets/plan_block_card.dart';
import 'widgets/plan_block_dialog.dart';

/// Screen displaying the daily agenda, date navigation strip, time blocks,
/// conflicts, and controls for scheduling, editing, deleting, or starting blocks.
class PlanScreen extends ConsumerWidget {
  const PlanScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final planAsync = ref.watch(dailyPlanControllerProvider);
    final controller = ref.read(dailyPlanControllerProvider.notifier);
    final dateString = ref.watch(selectedDateStringProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Daily Plan'),
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'plan_screen_fab',
        onPressed: () => _openScheduleDialog(context, ref, dateString),
        child: const Icon(Icons.add),
      ),
      body: planAsync.when(
        data: (planState) {
          return Column(
            children: [
              DateSelectorStrip(
                totalPlannedMs: planState.totalPlannedMs,
                totalActualMs: planState.totalActualMs,
              ),
              Expanded(
                child: planState.blocks.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Text(
                            'No blocks scheduled for this day.\nTap + to schedule an activity or routine.',
                            textAlign: TextAlign.center,
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurfaceVariant,
                                ),
                          ),
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: () => controller.refresh(),
                        child: ListView.builder(
                          itemCount: planState.blocks.length,
                          itemBuilder: (context, index) {
                            final block = planState.blocks[index];
                            final conflicts =
                                planState.conflicts[block.id] ?? [];

                            return PlanBlockCard(
                              block: block,
                              conflicts: conflicts,
                              onStart: () => _startBlock(context, ref, block),
                              onEdit: () => _editBlock(context, ref, block),
                              onDelete: () =>
                                  _confirmDelete(context, ref, block),
                            );
                          },
                        ),
                      ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error loading plan: $err')),
      ),
    );
  }

  Future<void> _openScheduleDialog(
    BuildContext context,
    WidgetRef ref,
    String planDate,
  ) async {
    final now = ref.read(wallClockProvider).utcNow.toLocal();
    final parts = planDate.split('-');
    final scheduledDate = parts.length == 3
        ? DateTime(
            int.parse(parts[0]),
            int.parse(parts[1]),
            int.parse(parts[2]),
            now.hour,
            now.minute,
          )
        : now;

    final block = await showDialog<PlanBlock>(
      context: context,
      builder: (ctx) => PlanBlockDialog(
        planDate: planDate,
        initialStartUtc: scheduledDate.toUtc(),
      ),
    );

    if (block != null) {
      await ref.read(dailyPlanControllerProvider.notifier).createBlock(block);
    }
  }

  Future<void> _editBlock(
    BuildContext context,
    WidgetRef ref,
    PlanBlock existing,
  ) async {
    final updated = await showDialog<PlanBlock>(
      context: context,
      builder: (ctx) => PlanBlockDialog(
        planDate: existing.planDate,
        initialStartUtc: existing.scheduledStartUtc,
        existingBlock: existing,
      ),
    );

    if (updated != null) {
      await ref.read(dailyPlanControllerProvider.notifier).updateBlock(updated);
    }
  }

  void _confirmDelete(BuildContext context, WidgetRef ref, PlanBlock block) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Block'),
        content:
            Text('Delete "${block.routineId ?? 'activity'}" from schedule?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              ref
                  .read(dailyPlanControllerProvider.notifier)
                  .deleteBlock(block.id);
            },
            child: Text(
              'Delete',
              style: TextStyle(color: Theme.of(ctx).colorScheme.error),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _startBlock(
    BuildContext context,
    WidgetRef ref,
    PlanBlock block,
  ) async {
    final title = block.routineId ?? 'Custom Activity';
    final res =
        await ref.read(activeTimerControllerProvider.notifier).startRoutine(
              title,
              planBlockId: block.id,
            );

    if (res.success && context.mounted) {
      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (ctx) => const ActiveTimerScreen(),
          fullscreenDialog: true,
        ),
      );
      if (!context.mounted) return;
      ref.read(dailyPlanControllerProvider.notifier).refresh();
    }
  }
}
