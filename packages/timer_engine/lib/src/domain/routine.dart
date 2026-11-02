import 'enums.dart';
import 'repeat_rule.dart';
import 'routine_phase.dart';

class Routine {
  final String id;
  final String name;
  final RepeatRule repeatRule;
  final List<RoutinePhase> phases;

  const Routine({
    required this.id,
    required this.name,
    required this.repeatRule,
    required this.phases,
  });

  TimerError? validate() {
    if (id.trim().isEmpty || name.trim().isEmpty) {
      return TimerError.invalidConfiguration;
    }
    if (phases.isEmpty) {
      return TimerError.invalidConfiguration;
    }
    if (!repeatRule.isValid) {
      return TimerError.invalidConfiguration;
    }

    final seenIds = <String>{};
    for (final phase in phases) {
      if (!phase.isValid) return TimerError.invalidConfiguration;
      if (seenIds.contains(phase.id)) return TimerError.invalidConfiguration;
      seenIds.add(phase.id);
    }
    return null;
  }

  Routine clone() {
    return Routine(
      id: id,
      name: name,
      repeatRule: RepeatRule(mode: repeatRule.mode, count: repeatRule.count),
      phases: phases.map((p) => p.copyWith()).toList(growable: false),
    );
  }

  Routine copyWith({
    String? id,
    String? name,
    RepeatRule? repeatRule,
    List<RoutinePhase>? phases,
  }) {
    return Routine(
      id: id ?? this.id,
      name: name ?? this.name,
      repeatRule: repeatRule ?? this.repeatRule,
      phases: phases ?? this.phases,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! Routine || runtimeType != other.runtimeType) return false;
    if (id != other.id ||
        name != other.name ||
        repeatRule != other.repeatRule) {
      return false;
    }
    if (phases.length != other.phases.length) return false;
    for (var i = 0; i < phases.length; i++) {
      if (phases[i] != other.phases[i]) return false;
    }
    return true;
  }

  @override
  int get hashCode => Object.hash(id, name, repeatRule, Object.hashAll(phases));
}
