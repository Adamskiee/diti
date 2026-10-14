import 'package:test/test.dart';
import 'package:timer_engine/timer_engine.dart';
import 'package:focus_flow_database/focus_flow_database.dart';

class StubNotificationPort implements NotificationPort {
  @override
  Future<void> scheduleBoundaryNotification({
    required String runId,
    required String phaseId,
    required String phaseName,
    required DateTime expectedUtc,
  }) async {}

  @override
  Future<void> cancelBoundaries(String runId) async {}
}

void main() {
  late FocusFlowDatabase db;
  late DriftRoutineRepository routineRepo;
  late DriftRunPersistencePort persistencePort;
  late DriftSessionRepository sessionRepo;
  late StubNotificationPort notificationPort;

  setUp(() {
    db = FocusFlowDatabase.inMemory();
    routineRepo = DriftRoutineRepository(db);
    persistencePort = DriftRunPersistencePort(db);
    sessionRepo = DriftSessionRepository(db);
    notificationPort = StubNotificationPort();
  });

  tearDown(() async {
    await db.close();
  });

  group('TimerEngine + Drift SQLite E2E Integration', () {
    test('executes full timer run, crash recovery, and session recording against SQLite', () async {
      // 1. Save Routine in Drift
      const routine = Routine(
        id: 'routine-e2e',
        name: 'Sprint Cycle',
        repeatRule: RepeatRule(mode: RepeatMode.count, count: 1),
        phases: [
          RoutinePhase(id: 'p-work', name: 'Work', durationMs: 1000, transition: TransitionPolicy.auto),
          RoutinePhase(id: 'p-rest', name: 'Rest', durationMs: 500, transition: TransitionPolicy.manual),
        ],
      );
      await routineRepo.saveRoutine(routine);

      // 2. Instantiate TimerEngine with Drift adapters
      final clock = SystemClock();
      final engine = TimerEngineImpl(
        routineRepository: routineRepo,
        persistencePort: persistencePort,
        notificationPort: notificationPort,
        monotonicClock: clock,
        wallClock: clock,
      );

      // 3. Start Routine
      final startRes = await engine.start('routine-e2e');
      expect(startRes.success, isTrue);
      final runId = engine.activeRunId!;

      // 4. Pause and Resume
      final pauseRes = await engine.pause(runId);
      expect(pauseRes.success, isTrue);

      var activeInDb = await persistencePort.getLatestActiveRun();
      expect(activeInDb, isNotNull);
      expect(activeInDb!.status, equals(RunStatus.paused));

      final resumeRes = await engine.resume(runId);
      expect(resumeRes.success, isTrue);

      activeInDb = await persistencePort.getLatestActiveRun();
      expect(activeInDb!.status, equals(RunStatus.running));

      // 5. Simulate App Crash & Restart: dispose old engine, create fresh engine
      engine.dispose();
      final newEngine = TimerEngineImpl(
        routineRepository: routineRepo,
        persistencePort: persistencePort,
        notificationPort: notificationPort,
        monotonicClock: clock,
        wallClock: clock,
      );

      // Verify no active run in memory before recover
      expect(newEngine.activeRunId, isNull);

      // 6. Recover
      await newEngine.recover();
      expect(newEngine.activeRunId, equals(runId));

      // 7. Finish Run
      final finishRes = await newEngine.finishRun(runId);
      expect(finishRes.success, isTrue);

      // Verify no active run remaining in DB
      final finalActive = await persistencePort.getLatestActiveRun();
      expect(finalActive, isNull);

      // 8. Record Session Record into SessionRepository
      final sessionRecord = SessionRecord(
        sessionId: 'session-e2e',
        routineId: routine.id,
        routineName: routine.name,
        startedAtUtc: DateTime.now().toUtc().subtract(const Duration(seconds: 10)),
        endedAtUtc: DateTime.now().toUtc(),
        totalDurationMs: 1500,
        outcome: SessionOutcome.completed,
        routineSnapshot: routine,
      );
      await sessionRepo.recordSession(sessionRecord);

      final retrievedSession = await sessionRepo.getSession('session-e2e');
      expect(retrievedSession, isNotNull);
      expect(retrievedSession!.totalDurationMs, equals(1500));
      expect(retrievedSession.routineSnapshot.name, equals('Sprint Cycle'));

      newEngine.dispose();
    });
  });
}
