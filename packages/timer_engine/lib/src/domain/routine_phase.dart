import 'enums.dart';

class RoutinePhase {
  final String id;
  final String name;
  final int? durationMs;
  final TransitionPolicy transition;

  const RoutinePhase({
    required this.id,
    required this.name,
    this.durationMs,
    required this.transition,
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
  }) {
    return RoutinePhase(
      id: id ?? this.id,
      name: name ?? this.name,
      durationMs: durationMs ?? this.durationMs,
      transition: transition ?? this.transition,
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
          transition == other.transition;

  @override
  int get hashCode => Object.hash(id, name, durationMs, transition);
}
