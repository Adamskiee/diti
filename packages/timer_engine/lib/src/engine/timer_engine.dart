import '../domain/command_result.dart';
import '../domain/timer_event.dart';
import '../domain/timer_run.dart';
import '../domain/timer_run_state.dart';

abstract interface class TimerEngine {
  String? get activeRunId;

  Future<TimerCommandResult> start(String routineId);
  Future<TimerCommandResult> pause(String runId);
  Future<TimerCommandResult> resume(String runId);
  Future<TimerCommandResult> skipPhase(String runId);
  Future<TimerCommandResult> finishPhase(String runId);
  Future<TimerCommandResult> finishRun(String runId);
  Future<TimerCommandResult> stop(String runId);
  Future<void> recover();
  void cancelBoundaryTimer();
  void dispose();

  TimerRun? getActiveRun();
  TimerRunState? getState(String runId);
  Future<Duration> elapsed(String runId);
  Stream<TimerRunState> get stateStream;
  Stream<TimerEvent> get eventStream;
}
