import 'package:focus_flow_database/focus_flow_database.dart';

import 'plan_block_conflict.dart';

/// State representation of the daily plan for a specific date.
class DailyPlanState {
  /// Date string formatted as 'YYYY-MM-DD'.
  final String dateString;

  /// Ordered list of plan blocks for this date, sorted chronologically.
  final List<PlanBlock> blocks;

  /// Mapping from plan block ID to the list of detected conflicts.
  final Map<String, List<PlanBlockConflict>> conflicts;

  /// Total duration of all planned blocks for the day in milliseconds.
  final int totalPlannedMs;

  /// Total duration actually spent on blocks for the day in milliseconds.
  final int totalActualMs;

  /// Creates a [DailyPlanState].
  const DailyPlanState({
    required this.dateString,
    required this.blocks,
    required this.conflicts,
    required this.totalPlannedMs,
    required this.totalActualMs,
  });

  /// Returns true if the block with [blockId] has at least one conflict.
  bool hasConflict(String blockId) =>
      conflicts.containsKey(blockId) && conflicts[blockId]!.isNotEmpty;
}
