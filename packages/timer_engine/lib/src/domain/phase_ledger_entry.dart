import 'enums.dart';

/// One phase's actual active time inside a run.
///
/// [durationMs] is the time the phase really ran, never its configured
/// length: a phase that was finished early or skipped contributes only the
/// active time it accumulated.
class PhaseLedgerEntry {
  final String phaseId;
  final String phaseName;
  final PhaseKind kind;
  final int phaseIndex;
  final int repeatIndex;
  final int durationMs;
  final PhaseStatus outcome;
  final DateTime startedAtUtc;
  final DateTime endedAtUtc;

  PhaseLedgerEntry({
    required this.phaseId,
    required this.phaseName,
    required this.kind,
    required this.phaseIndex,
    required this.repeatIndex,
    required this.durationMs,
    required this.outcome,
    required DateTime startedAtUtc,
    required DateTime endedAtUtc,
  })  : startedAtUtc =
            startedAtUtc.isUtc ? startedAtUtc : startedAtUtc.toUtc(),
        endedAtUtc = endedAtUtc.isUtc ? endedAtUtc : endedAtUtc.toUtc();

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PhaseLedgerEntry &&
          runtimeType == other.runtimeType &&
          phaseId == other.phaseId &&
          phaseName == other.phaseName &&
          kind == other.kind &&
          phaseIndex == other.phaseIndex &&
          repeatIndex == other.repeatIndex &&
          durationMs == other.durationMs &&
          outcome == other.outcome &&
          startedAtUtc == other.startedAtUtc &&
          endedAtUtc == other.endedAtUtc;

  @override
  int get hashCode => Object.hash(
        phaseId,
        phaseName,
        kind,
        phaseIndex,
        repeatIndex,
        durationMs,
        outcome,
        startedAtUtc,
        endedAtUtc,
      );
}
