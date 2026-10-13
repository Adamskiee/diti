import 'package:timer_engine/src/domain/timer_event.dart';
import 'package:timer_engine/src/domain/timer_run.dart';
import 'package:timer_engine/src/ports/run_persistence_port.dart';

class InMemoryPersistencePort implements RunPersistencePort {
  bool shouldFail = false;
  TimerRun? activeRun;
  final List<TimerEvent> committedEvents = [];

  @override
  Future<void> persistRunAndEvents(TimerRun run, List<TimerEvent> events) async {
    if (shouldFail) {
      throw const PersistenceException('Simulated storage write error');
    }
    activeRun = run;
    committedEvents.addAll(events);
  }

  @override
  Future<TimerRun?> getLatestActiveRun() async {
    if (shouldFail) {
      throw const PersistenceException('Simulated storage read error');
    }
    return activeRun;
  }
}
