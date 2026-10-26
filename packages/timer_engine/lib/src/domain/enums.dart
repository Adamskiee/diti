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

  /// Seeds a kind from a phase name. Shared by the editor, the migration
  /// and the starter routines so the rule exists in exactly one place.
  ///
  /// Whole-word matching, not substring: "Interest" and "Forest" contain
  /// "rest" but are ordinary focus phases, and a false rest classification
  /// silently under-reports the user's focus time.
  static PhaseKind inferFromName(String name) {
    const restHints = <String>[
      'break',
      'rest',
      'pause',
      'cooldown',
      'recover',
      'recovery',
      'lunch',
      'coffee',
    ];
    final words = name
        .toLowerCase()
        .split(RegExp('[^a-z0-9]+'))
        .where((word) => word.isNotEmpty);
    for (final word in words) {
      if (restHints.contains(word)) return PhaseKind.rest;
    }
    return PhaseKind.focus;
  }
}
