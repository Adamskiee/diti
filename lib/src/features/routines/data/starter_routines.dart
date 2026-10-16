import 'package:timer_engine/timer_engine.dart';

final starterRoutines = <Routine>[
  const Routine(
    id: 'pomodoro-default',
    name: 'Classic Pomodoro',
    repeatRule: RepeatRule(mode: RepeatMode.count, count: 4),
    phases: [
      RoutinePhase(
        id: 'pomodoro-focus',
        name: 'Focus',
        durationMs: 1500000, // 25 min
        transition: TransitionPolicy.auto,
      ),
      RoutinePhase(
        id: 'pomodoro-break',
        name: 'Short Break',
        durationMs: 300000, // 5 min
        transition: TransitionPolicy.auto,
      ),
    ],
  ),
  const Routine(
    id: 'deep-work-default',
    name: 'Deep Work',
    repeatRule: RepeatRule(mode: RepeatMode.count, count: 1),
    phases: [
      RoutinePhase(
        id: 'deep-work-focus',
        name: 'Deep Focus',
        durationMs: 3000000, // 50 min
        transition: TransitionPolicy.auto,
      ),
      RoutinePhase(
        id: 'deep-work-rest',
        name: 'Rest & Stretch',
        durationMs: 600000, // 10 min
        transition: TransitionPolicy.manual,
      ),
    ],
  ),
  const Routine(
    id: 'open-flow-default',
    name: 'Open Flow',
    repeatRule: RepeatRule(mode: RepeatMode.count, count: 1),
    phases: [
      RoutinePhase(
        id: 'open-flow-phase',
        name: 'Flow Session',
        durationMs: null, // open-ended
        transition: TransitionPolicy.manual,
      ),
      RoutinePhase(
        id: 'open-flow-cooldown',
        name: 'Cooldown',
        durationMs: 300000, // 5 min
        transition: TransitionPolicy.manual,
      ),
    ],
  ),
];

Future<bool> seedStarterRoutines(RoutineRepository repository) async {
  final existing = await repository.getAllRoutines();
  if (existing.isNotEmpty) {
    return false;
  }
  for (final routine in starterRoutines) {
    await repository.saveRoutine(routine);
  }
  return true;
}
