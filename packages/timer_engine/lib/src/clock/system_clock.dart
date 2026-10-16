import 'dart:async';
import 'cancelable_token.dart';
import 'monotonic_clock.dart';
import 'wall_clock.dart';

class SystemClock implements MonotonicClock, WallClock {
  final Stopwatch _stopwatch = Stopwatch()..start();

  @override
  int get nowMs => _stopwatch.elapsedMilliseconds;

  @override
  DateTime get utcNow => DateTime.now().toUtc();

  @override
  CancelableToken schedule(Duration delay, void Function() callback) {
    Timer? timer;
    final token = SimpleCancelableToken(
      onCancel: () => timer?.cancel(),
    );
    timer = Timer(delay, () {
      if (!token.isCancelled) {
        callback();
      }
    });
    return token;
  }
}

typedef SystemMonotonicClock = SystemClock;
typedef SystemWallClock = SystemClock;

