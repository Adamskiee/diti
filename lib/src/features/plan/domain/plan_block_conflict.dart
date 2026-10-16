/// Represents a detected scheduling conflict between two plan blocks or between
/// a candidate time slot and an existing block.
class PlanBlockConflict {
  /// The identifier of the primary block experiencing the conflict (or 'tentative').
  final String blockId;

  /// The identifier of the conflicting existing block.
  final String conflictingBlockId;

  /// Title or activity description of the conflicting block.
  final String conflictingTitle;

  /// Scheduled start time (UTC) of the conflicting block.
  final DateTime conflictingStartUtc;

  /// Scheduled end time (UTC) of the conflicting block.
  final DateTime conflictingEndUtc;

  /// Human-readable description of the conflict.
  final String description;

  /// Creates a [PlanBlockConflict].
  const PlanBlockConflict({
    required this.blockId,
    required this.conflictingBlockId,
    required this.conflictingTitle,
    required this.conflictingStartUtc,
    required this.conflictingEndUtc,
    required this.description,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PlanBlockConflict &&
          runtimeType == other.runtimeType &&
          blockId == other.blockId &&
          conflictingBlockId == other.conflictingBlockId;

  @override
  int get hashCode => Object.hash(blockId, conflictingBlockId);
}
