import '../domain/timer_event.dart';
import '../domain/timer_run.dart';

class PersistenceException implements Exception {
  final String message;
  const PersistenceException([this.message = 'Persistence operation failed']);

  @override
  String toString() => 'PersistenceException: $message';
}

abstract interface class RunPersistencePort {
  Future<void> persistRunAndEvents(TimerRun run, List<TimerEvent> events);
  Future<TimerRun?> getLatestActiveRun();
}
