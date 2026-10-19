import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/di/timer_engine_provider.dart';
import '../domain/daily_plan_state.dart';
import '../presentation/controllers/daily_plan_controller.dart';

/// Holds the currently selected calendar date for daily planning.
final selectedDateProvider = StateProvider<DateTime>((ref) {
  final wallClock = ref.watch(wallClockProvider);
  return wallClock.utcNow.toLocal();
});

/// Formats the selected date into 'YYYY-MM-DD' string for querying the database.
final selectedDateStringProvider = Provider<String>((ref) {
  final date = ref.watch(selectedDateProvider);
  final y = date.year.toString().padLeft(4, '0');
  final m = date.month.toString().padLeft(2, '0');
  final d = date.day.toString().padLeft(2, '0');
  return '$y-$m-$d';
});

/// Exposes the [DailyPlanController] managing [DailyPlanState].
final dailyPlanControllerProvider =
    AsyncNotifierProvider<DailyPlanController, DailyPlanState>(
  DailyPlanController.new,
);
