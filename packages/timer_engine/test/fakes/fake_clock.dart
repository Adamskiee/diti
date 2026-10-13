import 'package:timer_engine/src/clock/cancelable_token.dart';
import 'package:timer_engine/src/clock/monotonic_clock.dart';
import 'package:timer_engine/src/clock/wall_clock.dart';

class _ScheduledEntry {
  final int deadlineMs;
  final int sequence;
  final void Function() callback;
  final SimpleCancelableToken token;

  _ScheduledEntry({
    required this.deadlineMs,
    required this.sequence,
    required this.callback,
    required this.token,
  });
}

class FakeClock implements MonotonicClock, WallClock {
  int _currentMs = 0;
  DateTime _currentUtc;
  int _sequenceCounter = 0;
  final List<_ScheduledEntry> _scheduled = [];

  FakeClock({DateTime? initialUtc})
      : _currentUtc = initialUtc ?? DateTime.utc(2026, 1, 1, 0, 0, 0);

  @override
  int get nowMs => _currentMs;

  @override
  DateTime get utcNow => _currentUtc;

  void setWallClock(DateTime utc) {
    _currentUtc = utc.isUtc ? utc : utc.toUtc();
  }

  @override
  CancelableToken schedule(Duration delay, void Function() callback) {
    final deadline = _currentMs + delay.inMilliseconds;
    final token = SimpleCancelableToken();
    final entry = _ScheduledEntry(
      deadlineMs: deadline,
      sequence: _sequenceCounter++,
      callback: callback,
      token: token,
    );
    _scheduled.add(entry);
    _scheduled.sort((a, b) {
      final cmp = a.deadlineMs.compareTo(b.deadlineMs);
      if (cmp != 0) return cmp;
      return a.sequence.compareTo(b.sequence);
    });
    return token;
  }

  void advance(Duration duration) {
    if (duration.isNegative) {
      throw ArgumentError.value(
        duration,
        'duration',
        'Cannot advance FakeClock by a negative duration.',
      );
    }

    final targetMs = _currentMs + duration.inMilliseconds;

    while (_scheduled.isNotEmpty && _scheduled.first.deadlineMs <= targetMs) {
      final entry = _scheduled.removeAt(0);
      final deltaMs = entry.deadlineMs - _currentMs;
      _currentMs = entry.deadlineMs;
      _currentUtc = _currentUtc.add(Duration(milliseconds: deltaMs));
      if (!entry.token.isCancelled) {
        entry.callback();
      }
    }
    final remainingMs = targetMs - _currentMs;
    _currentUtc = _currentUtc.add(Duration(milliseconds: remainingMs));
    _currentMs = targetMs;
  }
}
