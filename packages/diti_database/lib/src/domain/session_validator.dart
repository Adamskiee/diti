import 'session_record.dart';

class SessionValidationError {
  final String field;
  final String message;

  const SessionValidationError({required this.field, required this.message});

  @override
  String toString() => '$field: $message';
}

class ValidationResult {
  final List<SessionValidationError> errors;

  const ValidationResult([this.errors = const []]);

  bool get isValid => errors.isEmpty;
}

class SessionValidationException implements Exception {
  final String message;
  final List<SessionValidationError> errors;

  const SessionValidationException(this.message, [this.errors = const []]);

  @override
  String toString() => 'SessionValidationException: $message';
}

class SessionValidator {
  static const int minDurationMs = 1000; // 1 second
  static const int maxDurationMs = 86400000; // 24 hours
  static const Duration maxFutureSkew = Duration(seconds: 60);

  static ValidationResult validate(
    SessionRecord session, {
    DateTime? nowUtc,
  }) {
    final errors = <SessionValidationError>[];
    final now = (nowUtc ?? DateTime.now()).toUtc();

    // 1. Duration checks
    if (session.totalDurationMs < minDurationMs) {
      errors.add(const SessionValidationError(
        field: 'totalDurationMs',
        message: 'Session duration must be at least 1 second.',
      ));
    }
    if (session.totalDurationMs > maxDurationMs) {
      errors.add(const SessionValidationError(
        field: 'totalDurationMs',
        message: 'Session duration cannot exceed 24 hours.',
      ));
    }

    // 2. Temporal consistency
    if (session.startedAtUtc.isAfter(session.endedAtUtc)) {
      errors.add(const SessionValidationError(
        field: 'endedAtUtc',
        message: 'Session end time cannot precede start time.',
      ));
    }
    if (session.endedAtUtc.isAfter(now.add(maxFutureSkew))) {
      errors.add(const SessionValidationError(
        field: 'endedAtUtc',
        message: 'Session end time cannot be in the future.',
      ));
    }

    // 3. Identification & Metadata
    if (session.sessionId.trim().isEmpty) {
      errors.add(const SessionValidationError(
        field: 'sessionId',
        message: 'Session ID cannot be empty.',
      ));
    }
    final routineId = session.routineId;
    if (routineId != null && routineId.trim().isEmpty) {
      errors.add(const SessionValidationError(
        field: 'routineId',
        message: 'Routine ID cannot be empty.',
      ));
    }
    if (session.routineName.trim().isEmpty) {
      errors.add(const SessionValidationError(
        field: 'routineName',
        message: 'Routine name cannot be empty.',
      ));
    }

    // 4. Events bounds
    for (final event in session.events) {
      if (event.durationMs < 0) {
        errors.add(SessionValidationError(
          field: 'events',
          message: 'Event duration cannot be negative: ${event.eventId}',
        ));
      }
      if (event.occurredAtUtc.isBefore(session.startedAtUtc.subtract(maxFutureSkew)) ||
          event.occurredAtUtc.isAfter(session.endedAtUtc.add(maxFutureSkew))) {
        errors.add(SessionValidationError(
          field: 'events',
          message: 'Event timestamp outside session range: ${event.eventId}',
        ));
      }
    }

    return ValidationResult(errors);
  }
}
