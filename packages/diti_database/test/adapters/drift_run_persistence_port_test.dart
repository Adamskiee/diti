import 'package:test/test.dart';
import 'package:timer_engine/timer_engine.dart';
import 'package:diti_database/src/database/diti_database.dart'
    hide Routine, RoutinePhase, TimerRun, TimerEvent;
import 'package:diti_database/src/repositories/drift_run_persistence_port.dart';

void main() {
  late DitiDatabase db;
  late DriftRunPersistencePort port;

  setUp(() {
    db = DitiDatabase.inMemory();
    port = DriftRunPersistencePort(db);
  });

  tearDown(() async {
    await db.close();
  });

  group('DriftRunPersistencePort', () {
    test('persists run and events atomically and restores active run across boundary', () async {
      const routine = Routine(
        id: 'r-persist',
        name: 'Work',
        repeatRule: RepeatRule(mode: RepeatMode.count, count: 1),
        phases: [
          RoutinePhase(id: 'p1', name: 'Focus', durationMs: 60000, transition: TransitionPolicy.auto),
        ],
      );

      final run = TimerRun(
        runId: 'run-persist-1',
        routineSnapshot: routine,
        status: RunStatus.running,
        phaseStatus: PhaseStatus.active,
        currentPhaseIndex: 0,
        repeatIndex: 0,
        accumulatedMs: 15000,
        phaseStartedAtUtc: DateTime.utc(2026, 10, 13, 12, 0),
        phaseStartedMonotonicMs: 50000,
        stateVersion: 3,
        lastEventId: 'ev-1',
      );

      final event = TimerEvent(
        eventId: 'ev-1',
        runId: run.runId,
        type: TimerEventType.runStarted,
        occurredAtUtc: DateTime.utc(2026, 10, 13, 12, 0),
      );

      await port.persistRunAndEvents(run, [event]);

      final restored = await port.getLatestActiveRun();
      expect(restored, isNotNull);
      expect(restored!.runId, equals(run.runId));
      expect(restored.status, equals(RunStatus.running));
      expect(restored.accumulatedMs, equals(15000));
      expect(restored.stateVersion, equals(3));
      expect(restored.lastEventId, equals('ev-1'));
      expect(restored.routineSnapshot, equals(routine));
      // Process boundary must reset monotonic ms to null
      expect(restored.phaseStartedMonotonicMs, isNull);
    });

    test('returns null when no active run exists', () async {
      final active = await port.getLatestActiveRun();
      expect(active, isNull);
    });

    test('a run round-trips its ledger and timestamps', () async {
      const routine = Routine(
        id: 'r-ledger',
        name: 'Ledger Work',
        repeatRule: RepeatRule(mode: RepeatMode.count, count: 1),
        phases: [
          RoutinePhase(id: 'p1', name: 'Focus', durationMs: 60000, transition: TransitionPolicy.auto),
          RoutinePhase(id: 'p2', name: 'Short Break', durationMs: 30000, transition: TransitionPolicy.auto),
        ],
      );

      final run = TimerRun(
        runId: 'run-ledger-1',
        routineSnapshot: routine,
        status: RunStatus.running,
        phaseStatus: PhaseStatus.active,
        currentPhaseIndex: 1,
        repeatIndex: 0,
        accumulatedMs: 60000,
        phaseStartedAtUtc: DateTime.utc(2026, 10, 21, 9, 25),
        stateVersion: 4,
        phaseLedger: [
          PhaseLedgerEntry(
            phaseId: 'p1',
            phaseName: 'Focus',
            kind: PhaseKind.focus,
            phaseIndex: 0,
            repeatIndex: 0,
            durationMs: 1500000,
            outcome: PhaseStatus.finished,
            startedAtUtc: DateTime.utc(2026, 10, 21, 9, 0),
            endedAtUtc: DateTime.utc(2026, 10, 21, 9, 25),
          ),
          PhaseLedgerEntry(
            phaseId: 'p2',
            phaseName: 'Short Break',
            kind: PhaseKind.rest,
            phaseIndex: 1,
            repeatIndex: 0,
            durationMs: 300000,
            outcome: PhaseStatus.active,
            startedAtUtc: DateTime.utc(2026, 10, 21, 9, 25),
            endedAtUtc: DateTime.utc(2026, 10, 21, 9, 30),
          ),
        ],
        runStartedAtUtc: DateTime.utc(2026, 10, 21, 9, 0),
        phaseFirstStartedAtUtc: DateTime.utc(2026, 10, 21, 9, 25),
      );

      await port.persistRunAndEvents(run, []);

      final restored = await port.getLatestActiveRun();
      expect(restored, isNotNull);
      expect(restored!.phaseLedger.length, equals(2));
      expect(restored.phaseLedger, equals(run.phaseLedger));
      expect(restored.phaseLedger.first.kind, equals(PhaseKind.focus));
      expect(restored.phaseLedger.last.kind, equals(PhaseKind.rest));
      expect(restored.runStartedAtUtc, equals(DateTime.utc(2026, 10, 21, 9, 0)));
      expect(
        restored.phaseFirstStartedAtUtc,
        equals(DateTime.utc(2026, 10, 21, 9, 25)),
      );
    });

    test('a corrupt ledger degrades to empty without throwing', () async {
      const routine = Routine(
        id: 'r-corrupt',
        name: 'Corrupt Work',
        repeatRule: RepeatRule(mode: RepeatMode.count, count: 1),
        phases: [
          RoutinePhase(id: 'p1', name: 'Focus', durationMs: 60000, transition: TransitionPolicy.auto),
        ],
      );

      final run = TimerRun(
        runId: 'run-corrupt-1',
        routineSnapshot: routine,
        status: RunStatus.running,
        phaseStatus: PhaseStatus.active,
        currentPhaseIndex: 0,
        repeatIndex: 0,
        accumulatedMs: 0,
        phaseStartedAtUtc: DateTime.utc(2026, 10, 21, 9, 0),
        stateVersion: 1,
      );

      await port.persistRunAndEvents(run, []);

      await db.customStatement(
        "UPDATE timer_runs SET phase_ledger_json = 'not json' WHERE run_id = ?",
        ['run-corrupt-1'],
      );

      // A corrupt ledger must never keep a run from being recovered.
      final restored = await port.getLatestActiveRun();
      expect(restored, isNotNull);
      expect(restored!.phaseLedger, isEmpty);
    });

    test('restores paused run with pausedAtUtc preserved', () async {
      const routine = Routine(
        id: 'r-paused',
        name: 'Work Paused',
        repeatRule: RepeatRule(mode: RepeatMode.count, count: 1),
        phases: [
          RoutinePhase(id: 'p1', name: 'Focus', durationMs: 60000, transition: TransitionPolicy.auto),
        ],
      );

      final pausedTime = DateTime.utc(2026, 10, 13, 12, 5);
      final run = TimerRun(
        runId: 'run-paused-1',
        routineSnapshot: routine,
        status: RunStatus.paused,
        phaseStatus: PhaseStatus.active,
        currentPhaseIndex: 0,
        repeatIndex: 0,
        accumulatedMs: 30000,
        phaseStartedAtUtc: DateTime.utc(2026, 10, 13, 12, 0),
        pausedAtUtc: pausedTime,
        stateVersion: 2,
      );

      await port.persistRunAndEvents(run, []);

      final restored = await port.getLatestActiveRun();
      expect(restored, isNotNull);
      expect(restored!.status, equals(RunStatus.paused));
      expect(restored.pausedAtUtc, equals(pausedTime));
      expect(restored.accumulatedMs, equals(30000));
    });

    test('rethrows PersistenceException if transaction fails', () async {
      final invalidRun = TimerRun(
        runId: 'invalid-run',
        routineSnapshot: const Routine(
          id: 'r',
          name: 'R',
          repeatRule: RepeatRule(mode: RepeatMode.count, count: 1),
          phases: [],
        ),
        status: RunStatus.running,
        phaseStatus: PhaseStatus.active,
        currentPhaseIndex: 0,
        repeatIndex: 0,
        accumulatedMs: 0,
        phaseStartedAtUtc: DateTime.now().toUtc(),
        stateVersion: 1,
      );

      // Trigger transaction rollback with foreign key violation by inserting event with mismatched runId
      final mismatchedEvent = TimerEvent(
        eventId: 'ev-orphan',
        runId: 'non-existent-run-id',
        type: TimerEventType.runStarted,
        occurredAtUtc: DateTime.now().toUtc(),
      );

      await expectLater(
        () => port.persistRunAndEvents(invalidRun, [mismatchedEvent]),
        throwsA(isA<PersistenceException>()),
      );
      expect(await port.getLatestActiveRun(), isNull);
    });
  });
}
