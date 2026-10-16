import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focus_flow/src/core/di/database_provider.dart';
import 'package:focus_flow/src/core/di/notification_providers.dart';
import 'package:focus_flow/src/core/di/repositories_provider.dart';
import 'package:focus_flow/src/core/di/timer_engine_provider.dart';
import 'package:focus_flow_database/focus_flow_database.dart';
import 'package:focus_flow_notifications/focus_flow_notifications.dart';
import 'package:timer_engine/timer_engine.dart';
import '../../helpers/test_fakes.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Riverpod DI Providers', () {
    test('Riverpod container instantiates all DI providers with test overrides', () async {
      final inMemoryDb = createInMemoryTestDatabase();
      final fakeClock = FakeClock(initialUtc: DateTime.utc(2026, 10, 16, 12, 0));
      final fakeClient = FakeNotificationClient();

      final container = ProviderContainer(
        overrides: [
          databaseProvider.overrideWithValue(inMemoryDb),
          monotonicClockProvider.overrideWithValue(fakeClock),
          wallClockProvider.overrideWithValue(fakeClock),
          notificationClientProvider.overrideWithValue(fakeClient),
        ],
      );

      final db = container.read(databaseProvider);
      final routineRepo = container.read(routineRepositoryProvider);
      final sessionRepo = container.read(sessionRepositoryProvider);
      final planBlockRepo = container.read(planBlockRepositoryProvider);
      final notificationPort = container.read(localNotificationPortProvider);
      final permissionService = container.read(notificationPermissionServiceProvider);
      final persistencePort = container.read(runPersistencePortProvider);
      final engine = container.read(timerEngineProvider);
      final coordinator = container.read(timerLifecycleCoordinatorProvider);

      expect(db, isA<FocusFlowDatabase>());
      expect(routineRepo, isA<RoutineRepository>());
      expect(sessionRepo, isA<SessionRepository>());
      expect(planBlockRepo, isA<PlanBlockRepository>());
      expect(notificationPort, isA<LocalNotificationPort>());
      expect(permissionService, isA<NotificationPermissionService>());
      expect(persistencePort, isA<RunPersistencePort>());
      expect(engine, isA<TimerEngine>());
      expect(coordinator, isA<TimerLifecycleCoordinator>());

      container.dispose();
      await inMemoryDb.close();
    });

    test('default clock providers instantiate system clocks', () {
      final container = ProviderContainer();
      final monoClock = container.read(monotonicClockProvider);
      final wallClock = container.read(wallClockProvider);

      expect(monoClock, isA<MonotonicClock>());
      expect(wallClock, isA<WallClock>());
      expect(monoClock.nowMs, isNonNegative);
      expect(wallClock.utcNow, isNotNull);

      container.dispose();
    });

    test('FakeNotificationClient tracks schedule and cancel operations', () async {
      final fake = FakeNotificationClient();

      expect(await fake.initialize(settings: null), isTrue);
      expect(await fake.pendingNotificationRequests(), isEmpty);
      expect(await fake.getNotificationAppLaunchDetails(), isNull);

      await fake.zonedSchedule(
        id: 42,
        title: 'Focus',
        body: 'Phase ended',
        scheduledDate: null,
        notificationDetails: null,
        androidScheduleMode: null,
        matchDateTimeComponents: null,
      );
      expect(fake.scheduledIds, contains(42));

      await fake.cancel(42);
      expect(fake.cancelledIds, contains(42));

      await fake.zonedSchedule(
        id: 99,
        title: 'Break',
        body: 'Break ended',
        scheduledDate: null,
        notificationDetails: null,
        androidScheduleMode: null,
        matchDateTimeComponents: null,
      );
      await fake.cancelAll();
      expect(fake.cancelledIds, contains(99));
    });
  });
}
