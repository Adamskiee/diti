import 'package:test/test.dart';
import 'package:timer_engine/src/clock/cancelable_token.dart';
import 'package:timer_engine/src/clock/system_clock.dart';

void main() {
  group('SimpleCancelableToken', () {
    test('initializes not cancelled', () {
      final token = SimpleCancelableToken();
      expect(token.isCancelled, isFalse);
    });

    test('cancel sets isCancelled and invokes onCancel callback once', () {
      var cancelCount = 0;
      final token = SimpleCancelableToken(
        onCancel: () => cancelCount++,
      );

      token.cancel();
      expect(token.isCancelled, isTrue);
      expect(cancelCount, equals(1));

      // Calling cancel again does not re-invoke callback
      token.cancel();
      expect(token.isCancelled, isTrue);
      expect(cancelCount, equals(1));
    });
  });

  group('SystemClock', () {
    test('reports monotonic time and utc wall clock', () async {
      final clock = SystemClock();

      final startMs = clock.nowMs;
      expect(startMs, greaterThanOrEqualTo(0));

      final utcNow = clock.utcNow;
      expect(utcNow.isUtc, isTrue);

      await Future<void>.delayed(const Duration(milliseconds: 15));
      expect(clock.nowMs, greaterThan(startMs));
    });

    test('schedule executes callback', () async {
      final clock = SystemClock();
      var executed = false;

      final token = clock.schedule(const Duration(milliseconds: 20), () {
        executed = true;
      });

      expect(token.isCancelled, isFalse);
      await Future<void>.delayed(const Duration(milliseconds: 50));
      expect(executed, isTrue);
    });

    test('cancelled token prevents execution', () async {
      final clock = SystemClock();
      var executed = false;

      final token = clock.schedule(const Duration(milliseconds: 30), () {
        executed = true;
      });

      token.cancel();
      expect(token.isCancelled, isTrue);

      await Future<void>.delayed(const Duration(milliseconds: 50));
      expect(executed, isFalse);
    });
  });
}
