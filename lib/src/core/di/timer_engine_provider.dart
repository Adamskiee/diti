import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:focus_flow_database/focus_flow_database.dart';
import 'package:focus_flow_notifications/focus_flow_notifications.dart';
import 'package:timer_engine/timer_engine.dart';
import 'database_provider.dart';
import 'notification_providers.dart';
import 'repositories_provider.dart';

final monotonicClockProvider = Provider<MonotonicClock>((ref) {
  return SystemMonotonicClock();
});

final wallClockProvider = Provider<WallClock>((ref) {
  return SystemWallClock();
});

final runPersistencePortProvider = Provider<RunPersistencePort>((ref) {
  final db = ref.watch(databaseProvider);
  return DriftRunPersistencePort(db);
});

final timerEngineProvider = Provider<TimerEngine>((ref) {
  final routineRepo = ref.watch(routineRepositoryProvider);
  final persistencePort = ref.watch(runPersistencePortProvider);
  final notificationPort = ref.watch(localNotificationPortProvider);
  final monotonicClock = ref.watch(monotonicClockProvider);
  final wallClock = ref.watch(wallClockProvider);

  final engine = TimerEngineImpl(
    routineRepository: routineRepo,
    persistencePort: persistencePort,
    notificationPort: notificationPort,
    monotonicClock: monotonicClock,
    wallClock: wallClock,
  );

  ref.onDispose(() => engine.dispose());
  return engine;
});

final timerLifecycleCoordinatorProvider =
    Provider<TimerLifecycleCoordinator>((ref) {
  final engine = ref.watch(timerEngineProvider);
  final notificationPort = ref.watch(localNotificationPortProvider);
  final permissionService = ref.watch(notificationPermissionServiceProvider);
  final wallClock = ref.watch(wallClockProvider);

  final coordinator = TimerLifecycleCoordinator(
    timerEngine: engine,
    notificationPort: notificationPort,
    wallClock: wallClock,
    permissionService: permissionService,
  );

  ref.onDispose(() => coordinator.dispose());
  return coordinator;
});
