import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timer_engine/timer_engine.dart';
import '../providers/routines_providers.dart';
import 'widgets/routine_card.dart';

class RoutineListScreen extends ConsumerWidget {
  final void Function(Routine routine)? onStartRoutine;
  final void Function(String? routineId)? onEditRoutine;

  const RoutineListScreen({
    super.key,
    this.onStartRoutine,
    this.onEditRoutine,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final routinesAsync = ref.watch(routineListControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Routines'),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => onEditRoutine?.call(null),
        child: const Icon(Icons.add),
      ),
      body: routinesAsync.when(
        data: (routines) {
          if (routines.isEmpty) {
            return const Center(
              child: Text('No routines found. Tap + to create one!'),
            );
          }
          return RefreshIndicator(
            onRefresh: () => ref.read(routineListControllerProvider.notifier).refresh(),
            child: ListView.builder(
              itemCount: routines.length,
              itemBuilder: (context, index) {
                final routine = routines[index];
                return RoutineCard(
                  routine: routine,
                  onStart: () => onStartRoutine?.call(routine),
                  onTap: () => onEditRoutine?.call(routine.id),
                  onDuplicate: () => ref
                      .read(routineListControllerProvider.notifier)
                      .duplicateRoutine(routine),
                  onDelete: () => _confirmDelete(context, ref, routine),
                );
              },
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
      ),
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref, Routine routine) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Routine'),
        content: Text('Are you sure you want to delete "${routine.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              ref
                  .read(routineListControllerProvider.notifier)
                  .deleteRoutine(routine.id);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
