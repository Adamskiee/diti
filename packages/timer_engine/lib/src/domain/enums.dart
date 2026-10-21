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

enum PhaseKind {
  focus,
  rest;

  /// Seeds a kind from a phase name. Shared by the editor, the migration and
  /// the starter routines so the rule exists in exactly one place.
  static PhaseKind inferFromName(String name) {
    const restHints = <String>[
      'break', 'rest', 'pause', 'cooldown', 'recover', 'recovery', 'lunch', 'coffee',
    ];
    final lower = name.toLowerCase();
    for (final hint in restHints) {
      if (lower.contains(hint)) return PhaseKind.rest;
    }
    return PhaseKind.focus;
  }
}
