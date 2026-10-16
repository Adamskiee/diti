import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:focus_flow_database/focus_flow_database.dart';

import '../../../../core/di/repositories_provider.dart';
import '../../domain/daily_plan_state.dart';
import '../../domain/plan_block_conflict.dart';
import '../../domain/plan_block_conflict_detector.dart';
import '../../providers/plan_providers.dart';

/// Controller managing the daily planning state, date navigation, CRUD operations
/// on plan blocks, and tentative conflict checks.
class DailyPlanController extends AsyncNotifier<DailyPlanState> {
  @override
  FutureOr<DailyPlanState> build() async {
    final dateString = ref.watch(selectedDateStringProvider);
    final repo = ref.watch(planBlockRepositoryProvider);

    return _fetchDailyPlanState(dateString: dateString, repo: repo);
  }

  Future<DailyPlanState> _fetchDailyPlanState({
    required String dateString,
    required PlanBlockRepository repo,
  }) async {
    final rawBlocks = await repo.getBlocksForDate(dateString);
    final sorted = List<PlanBlock>.from(rawBlocks)
      ..sort((a, b) => a.scheduledStartUtc.compareTo(b.scheduledStartUtc));

    final conflicts = PlanBlockConflictDetector.detectConflicts(sorted);

    int totalPlanned = 0;
    int totalActual = 0;
    for (final b in sorted) {
      totalPlanned += b.plannedDurationMs;
      if (b.actualDurationMs != null) {
        totalActual += b.actualDurationMs!;
      }
    }

    return DailyPlanState(
      dateString: dateString,
      blocks: sorted,
      conflicts: conflicts,
      totalPlannedMs: totalPlanned,
      totalActualMs: totalActual,
    );
  }

  /// Refreshes the daily plan state for the currently selected date.
  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final dateString = ref.read(selectedDateStringProvider);
      final repo = ref.read(planBlockRepositoryProvider);
      return _fetchDailyPlanState(dateString: dateString, repo: repo);
    });
  }

  /// Creates a new [PlanBlock] in the repository and refreshes the state.
  Future<void> createBlock(PlanBlock block) async {
    final repo = ref.read(planBlockRepositoryProvider);
    await repo.createPlanBlock(block);
    await refresh();
  }

  /// Updates an existing [PlanBlock] in the repository and refreshes the state.
  Future<void> updateBlock(PlanBlock block) async {
    final repo = ref.read(planBlockRepositoryProvider);
    await repo.updatePlanBlock(block);
    await refresh();
  }

  /// Deletes a [PlanBlock] by [id] from the repository and refreshes the state.
  Future<void> deleteBlock(String id) async {
    final repo = ref.read(planBlockRepositoryProvider);
    await repo.deletePlanBlock(id);
    await refresh();
  }

  /// Checks if a tentative block starting at [startUtc] with duration [durationMs]
  /// would conflict with any existing blocks in the currently loaded state.
  List<PlanBlockConflict> checkTentativeConflict({
    required DateTime startUtc,
    required int durationMs,
    String? excludeBlockId,
  }) {
    final current = state.valueOrNull?.blocks ?? [];
    return PlanBlockConflictDetector.checkTentativeConflict(
      startUtc: startUtc,
      durationMs: durationMs,
      existingBlocks: current,
      excludeBlockId: excludeBlockId,
    );
  }

  /// Sets the selected date to [date].
  void setDate(DateTime date) {
    ref.read(selectedDateProvider.notifier).state = date;
  }

  /// Advances the selected date by one day.
  void nextDay() {
    final current = ref.read(selectedDateProvider);
    setDate(DateTime(current.year, current.month, current.day + 1));
  }

  /// Moves the selected date back by one day.
  void previousDay() {
    final current = ref.read(selectedDateProvider);
    setDate(DateTime(current.year, current.month, current.day - 1));
  }

  /// Resets the selected date to today.
  void setToday() {
    setDate(DateTime.now());
  }
}
