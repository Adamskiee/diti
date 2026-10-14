import 'package:flutter/widgets.dart';
import 'package:timer_engine/timer_engine.dart';
import '../adapters/local_notification_port.dart';
import '../permissions/notification_permission_service.dart';

/// Coordinates background lifecycle transitions for FocusFlow timers.
///
/// On app pause, it pre-schedules rolling boundaries using [LocalNotificationPort].
/// On app resume, it triggers crash recovery on [TimerEngine] and clears stale rolling boundaries.
class TimerLifecycleCoordinator {
  final TimerEngine _timerEngine;
  final LocalNotificationPort _notificationPort;
  final WallClock _wallClock;
  final NotificationPermissionService _permissionService;
  AppLifecycleListener? _lifecycleListener;

  TimerLifecycleCoordinator({
    required TimerEngine timerEngine,
    required LocalNotificationPort notificationPort,
    required WallClock wallClock,
    NotificationPermissionService? permissionService,
    bool attachLifecycleListener = true,
  })  : _timerEngine = timerEngine,
        _notificationPort = notificationPort,
        _wallClock = wallClock,
        _permissionService =
            permissionService ?? FlutterNotificationPermissionService() {
    if (attachLifecycleListener) {
      _lifecycleListener = AppLifecycleListener(
        onResume: onResume,
        onPause: onPause,
      );
    }
  }

  /// Initializes the coordinator and recovers timer engine state if an active run exists.
  Future<void> initialize() async {
    await _timerEngine.recover();
  }

  /// Invoked when the app lifecycle transitions to resumed.
  Future<void> onResume() async {
    final activeRunId = _timerEngine.activeRunId;
    if (activeRunId != null) {
      await _notificationPort.cancelBoundaries(activeRunId);
    }
    await _timerEngine.recover();
  }

  /// Invoked when the app lifecycle transitions to paused.
  Future<void> onPause() async {
    final activeRunId = _timerEngine.activeRunId;
    if (activeRunId == null) return;

    final run = _timerEngine.getActiveRun();
    if (run != null && run.status == RunStatus.running) {
      _timerEngine.cancelBoundaryTimer();
      final status = await _permissionService.checkStatus();
      await _notificationPort.scheduleRollingBoundaries(
        run: run,
        currentUtc: _wallClock.utcNow,
        allowExactAlarms: status.exactAlarmsAllowed,
      );
    }
  }

  /// Cleans up the lifecycle listener.
  void dispose() {
    _lifecycleListener?.dispose();
  }
}
