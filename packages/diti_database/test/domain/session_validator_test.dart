import 'package:test/test.dart';
import 'package:diti_database/src/domain/session_record.dart';
import 'package:diti_database/src/domain/session_validator.dart';
import 'package:timer_engine/timer_engine.dart';

void main() {
  group('SessionValidator', () {
    const routine = Routine(
      id: 'routine-1',
      name: 'Deep Work',
      repeatRule: RepeatRule(mode: RepeatMode.count, count: 1),
      phases: [
        RoutinePhase(
          id: 'p1',
          name: 'Focus',
          durationMs: 1500000,
          transition: TransitionPolicy.manual,
        ),
      ],
    );

    SessionRecord createValidSession({
      String sessionId = 'sess-1',
      String routineId = 'routine-1',
      String routineName = 'Deep Work',
      DateTime? startedAtUtc,
      DateTime? endedAtUtc,
      int totalDurationMs = 1500000,
      SessionOutcome outcome = SessionOutcome.completed,
      List<SessionEventRecord> events = const [],
    }) {
      final start = startedAtUtc ?? DateTime.utc(2026, 10, 20, 10, 0);
      final end = endedAtUtc ?? start.add(Duration(milliseconds: totalDurationMs));
      return SessionRecord(
        sessionId: sessionId,
        routineId: routineId,
        routineName: routineName,
        startedAtUtc: start,
        endedAtUtc: end,
        totalDurationMs: totalDurationMs,
        outcome: outcome,
        routineSnapshot: routine,
        events: events,
      );
    }

    test('valid session passes validation with zero errors', () {
      final session = createValidSession();
      final result = SessionValidator.validate(
        session,
        nowUtc: DateTime.utc(2026, 10, 20, 11, 0),
      );
      expect(result.isValid, isTrue);
      expect(result.errors, isEmpty);
    });

    test('rejects totalDurationMs less than 1000ms', () {
      final session = createValidSession(totalDurationMs: 999);
      final result = SessionValidator.validate(session);
      expect(result.isValid, isFalse);
      expect(result.errors.any((e) => e.field == 'totalDurationMs'), isTrue);
    });

    test('rejects totalDurationMs greater than 24 hours', () {
      final session = createValidSession(totalDurationMs: 86400001);
      final result = SessionValidator.validate(session);
      expect(result.isValid, isFalse);
      expect(result.errors.any((e) => e.field == 'totalDurationMs'), isTrue);
    });

    test('rejects endedAtUtc before startedAtUtc', () {
      final start = DateTime.utc(2026, 10, 20, 10, 30);
      final end = DateTime.utc(2026, 10, 20, 10, 0);
      final session = createValidSession(
        startedAtUtc: start,
        endedAtUtc: end,
        totalDurationMs: 1500000,
      );
      final result = SessionValidator.validate(session);
      expect(result.isValid, isFalse);
      expect(result.errors.any((e) => e.field == 'endedAtUtc'), isTrue);
    });

    test('rejects endedAtUtc in the future beyond clock skew', () {
      final now = DateTime.utc(2026, 10, 20, 10, 0);
      final session = createValidSession(
        startedAtUtc: now,
        endedAtUtc: now.add(const Duration(minutes: 5)),
        totalDurationMs: 300000,
      );
      final result = SessionValidator.validate(session, nowUtc: now);
      expect(result.isValid, isFalse);
      expect(result.errors.any((e) => e.field == 'endedAtUtc'), isTrue);
    });

    test('rejects empty sessionId, routineId, and routineName', () {
      final session = createValidSession(
        sessionId: '  ',
        routineId: '  ',
        routineName: '   ',
      );
      final result = SessionValidator.validate(session);
      expect(result.isValid, isFalse);
      expect(result.errors.any((e) => e.field == 'sessionId'), isTrue);
      expect(result.errors.any((e) => e.field == 'routineId'), isTrue);
      expect(result.errors.any((e) => e.field == 'routineName'), isTrue);
    });

    test('rejects event with negative duration or timestamp out of range', () {
      final start = DateTime.utc(2026, 10, 20, 10, 0);
      final end = DateTime.utc(2026, 10, 20, 10, 25);
      final session = createValidSession(
        startedAtUtc: start,
        endedAtUtc: end,
        totalDurationMs: 25 * 60 * 1000,
        events: [
          SessionEventRecord(
            eventId: 'evt-1',
            sessionId: 'sess-1',
            eventType: 'phaseCompleted',
            occurredAtUtc: DateTime.utc(2026, 10, 20, 9, 0), // Outside session range
            durationMs: -50, // Negative duration
          ),
        ],
      );
      final result = SessionValidator.validate(session);
      expect(result.isValid, isFalse);
      expect(result.errors.where((e) => e.field == 'events').length, equals(2));
    });
  });
}
