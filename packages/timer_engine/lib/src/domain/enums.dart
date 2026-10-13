enum RunStatus {
  idle,
  running,
  paused,
  completed,
  cancelled,
}

enum PhaseStatus {
  active,
  awaitingAction,
  finished,
  skipped,
}

enum TransitionPolicy {
  auto,
  manual,
}

enum RepeatMode {
  count,
  forever,
}

enum TimerError {
  invalidConfiguration,
  invalidTransition,
  runNotFound,
  staleState,
  persistenceFailure,
}
