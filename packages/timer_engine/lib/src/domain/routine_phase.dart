import 'enums.dart';

class RoutinePhase {
  final String id;
  final String name;
  final int? durationMs;
  final TransitionPolicy transition;
  final PhaseKind kind;

  const RoutinePhase({
    required this.id,
    required this.name,
    this.durationMs,
    required this.transition,
    this.kind = PhaseKind.focus,
  });

  bool get isOpenEnded => durationMs == null;

  bool get isValid {
    if (id.trim().isEmpty || name.trim().isEmpty) return false;
    if (durationMs != null && durationMs! <= 0) return false;
    // Open-ended phase cannot auto-advance
    if (isOpenEnded && transition == TransitionPolicy.auto) return false;
    return true;
  }

  RoutinePhase copyWith({
    String? id,
    String? name,
    int? durationMs,
    TransitionPolicy? transition,
    PhaseKind? kind,
  }) {
    return RoutinePhase(
      id: id ?? this.id,
      name: name ?? this.name,
      durationMs: durationMs ?? this.durationMs,
      transition: transition ?? this.transition,
      kind: kind ?? this.kind,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RoutinePhase &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          name == other.name &&
          durationMs == other.durationMs &&
          transition == other.transition &&
          kind == other.kind;

  @override
  int get hashCode => Object.hash(id, name, durationMs, transition, kind);
}
