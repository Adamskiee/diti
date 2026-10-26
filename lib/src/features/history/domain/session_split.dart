import 'package:diti_database/diti_database.dart';
import 'package:timer_engine/timer_engine.dart';

/// A session's active time, split by the kind of the phase it was spent in.
typedef SessionFocusRest = ({
  /// The time spent in focus phases.
  int focusMs,

  /// The time spent in rest phases.
  int restMs,
});

/// Splits a session's phase events into the time spent in focus phases and
/// the time spent in rest phases.
///
/// The kind is the one the phase was recorded with, so a phase renamed after
/// the session keeps the kind it ran as.
///
/// Returns null when the session recorded no events: there is no breakdown to
/// split. A session recorded before the per-phase breakdown existed has no
/// events at all, and its history is never reinterpreted - what an unsplit
/// session means is the caller's decision.
SessionFocusRest? splitSessionByKind(List<SessionEventRecord> events) {
  if (events.isEmpty) return null;

  var focusMs = 0;
  var restMs = 0;
  for (final event in events) {
    if (event.kind == PhaseKind.rest) {
      restMs += event.durationMs;
    } else {
      focusMs += event.durationMs;
    }
  }
  return (focusMs: focusMs, restMs: restMs);
}
