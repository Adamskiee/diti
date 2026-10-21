import 'package:diti_database/diti_database.dart';
import 'package:timer_engine/timer_engine.dart';

class DraftSessionState {
  final SessionRecord? candidateSession;
  final String? planBlockId;
  final int draftDurationMs;
  final String draftRoutineName;
  final bool isVisible;
  final bool isSaving;
  final String? validationError;

  /// The phases the run recorded, with the active time each of them took.
  /// Its durations always add up to [draftDurationMs].
  final List<PhaseLedgerEntry> phaseBreakdown;

  const DraftSessionState({
    this.candidateSession,
    this.planBlockId,
    this.draftDurationMs = 0,
    this.draftRoutineName = '',
    this.isVisible = false,
    this.isSaving = false,
    this.validationError,
    this.phaseBreakdown = const [],
  });

  DraftSessionState copyWith({
    SessionRecord? candidateSession,
    String? planBlockId,
    int? draftDurationMs,
    String? draftRoutineName,
    bool? isVisible,
    bool? isSaving,
    String? validationError,
    bool clearValidationError = false,
    List<PhaseLedgerEntry>? phaseBreakdown,
  }) {
    return DraftSessionState(
      candidateSession: candidateSession ?? this.candidateSession,
      planBlockId: planBlockId ?? this.planBlockId,
      draftDurationMs: draftDurationMs ?? this.draftDurationMs,
      draftRoutineName: draftRoutineName ?? this.draftRoutineName,
      isVisible: isVisible ?? this.isVisible,
      isSaving: isSaving ?? this.isSaving,
      validationError: clearValidationError
          ? null
          : (validationError ?? this.validationError),
      phaseBreakdown: phaseBreakdown ?? this.phaseBreakdown,
    );
  }
}
