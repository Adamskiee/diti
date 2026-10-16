import 'package:focus_flow_database/focus_flow_database.dart';

import 'plan_block_conflict.dart';

/// Pure utility that detects interval conflicts between scheduled [PlanBlock]s
/// and against candidate (tentative) time intervals.
///
/// Intervals are modeled as half-open: [start, end).
/// Exact boundary touches (e.g. Block A ends at 10:00 and Block B starts at 10:00)
/// do not conflict.
class PlanBlockConflictDetector {
  const PlanBlockConflictDetector._();

  /// Scans a list of [PlanBlock]s and returns a mapping from each conflicting
  /// block's ID to a list of detected [PlanBlockConflict] records.
  static Map<String, List<PlanBlockConflict>> detectConflicts(
    List<PlanBlock> blocks,
  ) {
    final result = <String, List<PlanBlockConflict>>{};
    if (blocks.length < 2) return result;

    for (int i = 0; i < blocks.length; i++) {
      final a = blocks[i];
      final startA = a.scheduledStartUtc;
      final endA = startA.add(Duration(milliseconds: a.plannedDurationMs));

      for (int j = i + 1; j < blocks.length; j++) {
        final b = blocks[j];
        final startB = b.scheduledStartUtc;
        final endB = startB.add(Duration(milliseconds: b.plannedDurationMs));

        // Overlap condition for half-open intervals [S_A, E_A) and [S_B, E_B):
        // S_A < E_B && S_B < E_A
        if (startA.isBefore(endB) && startB.isBefore(endA)) {
          final titleA = a.routineId ?? 'Activity';
          final titleB = b.routineId ?? 'Activity';

          final descForA =
              'Overlaps with $titleB (${_formatTime(startB)} - ${_formatTime(endB)})';
          final descForB =
              'Overlaps with $titleA (${_formatTime(startA)} - ${_formatTime(endA)})';

          result.putIfAbsent(a.id, () => []).add(
                PlanBlockConflict(
                  blockId: a.id,
                  conflictingBlockId: b.id,
                  conflictingTitle: titleB,
                  conflictingStartUtc: startB,
                  conflictingEndUtc: endB,
                  description: descForA,
                ),
              );

          result.putIfAbsent(b.id, () => []).add(
                PlanBlockConflict(
                  blockId: b.id,
                  conflictingBlockId: a.id,
                  conflictingTitle: titleA,
                  conflictingStartUtc: startA,
                  conflictingEndUtc: endA,
                  description: descForB,
                ),
              );
        }
      }
    }

    return result;
  }

  /// Checks a candidate time interval ([startUtc], [durationMs]) against existing blocks.
  ///
  /// Can optionally ignore an existing block by specifying [excludeBlockId]
  /// (e.g. when editing or rescheduling an existing block).
  static List<PlanBlockConflict> checkTentativeConflict({
    required DateTime startUtc,
    required int durationMs,
    required List<PlanBlock> existingBlocks,
    String? excludeBlockId,
  }) {
    final conflicts = <PlanBlockConflict>[];
    final endUtc = startUtc.add(Duration(milliseconds: durationMs));

    for (final b in existingBlocks) {
      if (excludeBlockId != null && b.id == excludeBlockId) continue;

      final startB = b.scheduledStartUtc;
      final endB = startB.add(Duration(milliseconds: b.plannedDurationMs));

      if (startUtc.isBefore(endB) && startB.isBefore(endUtc)) {
        final titleB = b.routineId ?? 'Scheduled Block';
        conflicts.add(
          PlanBlockConflict(
            blockId: 'tentative',
            conflictingBlockId: b.id,
            conflictingTitle: titleB,
            conflictingStartUtc: startB,
            conflictingEndUtc: endB,
            description:
                'Conflicts with "$titleB" (${_formatTime(startB)} - ${_formatTime(endB)})',
          ),
        );
      }
    }

    return conflicts;
  }

  static String _formatTime(DateTime dt) {
    final local = dt.toLocal();
    final h = local.hour.toString().padLeft(2, '0');
    final m = local.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }
}
