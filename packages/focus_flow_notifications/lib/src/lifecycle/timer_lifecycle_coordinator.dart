import 'package:flutter/widgets.dart';
import 'package:timer_engine/timer_engine.dart';
import '../adapters/local_notification_port.dart';

/// Coordinates background lifecycle transitions for FocusFlow timers.
///
/// On app pause/hide, it pre-schedules rolling boundaries using [LocalNotificationPort].
/// On app resume, it triggers crash recovery on [TimerEngine].
class TimerLifecycleCoordinator {
  final TimerEngine _timerEngine;
  final LocalNotificationPort _notificationPort;
  final WallClock _wallClock;
  AppLifecycleListener? _lifecycleListener;

  TimerLifecycleCoordinator({
    required TimerEngine timerEngine,
    required LocalNotificationPort notificationPort,
    required WallClock wallClock,
    bool attachLifecycleListener = true,
  })  : _timerEngine = timerEngine,
        _notificationPort = notificationPort,
        _wallClock = wallClock {
    if (attachLifecycleListener) {
      _lifecycleListener = AppLifecycleListener(
        onResume: onResume,
        onPause: onPause,
        onHide: onPause,
      );
    }
  }

  /// Initializes the coordinator and recovers timer engine state if an active run exists.
  Future<void> initialize() async {
    await _timerEngine.recover();
  }

  /// Invoked when the app lifecycle transitions to resumed.
  Future<void> onResume() async {
    await _timerEngine.recover();
  }

  /// Invoked when the app lifecycle transitions to paused or hidden.
  Future<void> onPause() async {
    final activeRunId = _timerEngine.activeRunId;
    if (activeRunId == null) return;

    final run = _timerEngine.getActiveRun();
    if (run != null && run.status == RunStatus.running) {
      await _notificationPort.scheduleRollingBoundaries(
        run: run,
        currentUtc: _wallClock.utcNow,
      );
    }
  }

  /// Cleans up the lifecycle listener.
  void dispose() {
    _lifecycleListener?.dispose();
  }
}
