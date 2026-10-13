import 'package:test/test.dart';
import '../fakes/fake_clock.dart';

void main() {
  group('FakeClock', () {
    test('advances monotonic time and executes scheduled callbacks in order',
        () {
      final clock = FakeClock(initialUtc: DateTime.utc(2026, 10, 13, 9, 0, 0));
      final executionLog = <String>[];

      clock.schedule(const Duration(minutes: 5), () {
        executionLog.add('5-min');
      });
      clock.schedule(const Duration(minutes: 10), () {
        executionLog.add('10-min');
      });

      clock.advance(const Duration(minutes: 3));
      expect(clock.nowMs, equals(180000));
      expect(executionLog, isEmpty);

      clock.advance(const Duration(minutes: 4)); // now at 7 minutes
      expect(clock.nowMs, equals(420000));
      expect(executionLog, equals(['5-min']));

      clock.advance(const Duration(minutes: 5)); // now at 12 minutes
      expect(executionLog, equals(['5-min', '10-min']));
    });

    test('cancelled token does not execute when deadline is reached', () {
      final clock = FakeClock();
      var executed = false;

      final token = clock.schedule(const Duration(minutes: 5), () {
        executed = true;
      });

      token.cancel();
      expect(token.isCancelled, isTrue);

      clock.advance(const Duration(minutes: 10));
      expect(executed, isFalse);
    });

    test('wall clock can be shifted independently for time test scenarios', () {
      final initial = DateTime.utc(2026, 10, 13, 10, 0, 0);
      final clock = FakeClock(initialUtc: initial);

      expect(clock.utcNow, equals(initial));

      final backward = DateTime.utc(2026, 10, 13, 9, 30, 0);
      clock.setWallClock(backward);
      expect(clock.utcNow, equals(backward));
      // Monotonic time must not be affected by wall clock manipulation
      expect(clock.nowMs, equals(0));
    });

    test('preserves FIFO execution order for simultaneous callbacks', () {
      final clock = FakeClock();
      final executionLog = <String>[];

      clock.schedule(const Duration(minutes: 5), () {
        executionLog.add('first');
      });
      clock.schedule(const Duration(minutes: 5), () {
        executionLog.add('second');
      });

      clock.advance(const Duration(minutes: 5));
      expect(executionLog, equals(['first', 'second']));
    });

    test('advancing wall clock when advancing duration', () {
      final initial = DateTime.utc(2026, 10, 13, 10, 0, 0);
      final clock = FakeClock(initialUtc: initial);

      clock.advance(const Duration(minutes: 15));
      expect(clock.utcNow, equals(DateTime.utc(2026, 10, 13, 10, 15, 0)));
      expect(clock.nowMs, equals(15 * 60 * 1000));
    });

    test('setWallClock converts non-utc DateTime to utc', () {
      final clock = FakeClock();
      final localTime = DateTime(2026, 10, 13, 12, 0, 0);
      clock.setWallClock(localTime);
      expect(clock.utcNow.isUtc, isTrue);
      expect(clock.utcNow, equals(localTime.toUtc()));
    });

    test('synchronizes utcNow with intermediate scheduled callback deadlines',
        () {
      final initial = DateTime.utc(2026, 10, 13, 10, 0, 0);
      final clock = FakeClock(initialUtc: initial);
      DateTime? observedUtcAt5Min;
      int? observedMsAt5Min;

      clock.schedule(const Duration(minutes: 5), () {
        observedUtcAt5Min = clock.utcNow;
        observedMsAt5Min = clock.nowMs;
      });

      clock.advance(const Duration(minutes: 10));

      expect(observedMsAt5Min, equals(300000));
      expect(observedUtcAt5Min, equals(DateTime.utc(2026, 10, 13, 10, 5, 0)));
      expect(clock.nowMs, equals(600000));
      expect(clock.utcNow, equals(DateTime.utc(2026, 10, 13, 10, 10, 0)));
    });

    test('throws ArgumentError when advancing by negative duration', () {
      final clock = FakeClock();
      expect(
        () => clock.advance(const Duration(seconds: -1)),
        throwsArgumentError,
      );
    });
  });
}
