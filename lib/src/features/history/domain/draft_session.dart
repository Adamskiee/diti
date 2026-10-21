import 'package:diti_database/diti_database.dart';

class DraftSessionState {
  final SessionRecord? candidateSession;
  final String? planBlockId;
  final int draftDurationMs;
  final String draftRoutineName;
  final bool isVisible;
  final bool isSaving;
  final String? validationError;

  const DraftSessionState({
    this.candidateSession,
    this.planBlockId,
    this.draftDurationMs = 0,
    this.draftRoutineName = '',
    this.isVisible = false,
    this.isSaving = false,
    this.validationError,
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
    );
  }
}
