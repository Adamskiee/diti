import 'package:diti_tracker/diti_tracker.dart';
import 'package:test/test.dart';

class MockTrackerPort implements AppTrackerPort {
  ActiveAppSample? sample;
  @override
  Future<ActiveAppSample?> sampleActiveWindow() async => sample;
}

void main() {
  group('ContinuousActivityTracker', () {
    test('samples active window on tick and invokes onSample', () async {
      final port = MockTrackerPort();
      port.sample = ActiveAppSample(
        rawClass: 'code',
        rawTitle: 'main.dart - diti',
        sampledAt: DateTime.utc(2026, 11, 1, 10, 0, 3),
      );

      final samples = <Map<String, dynamic>>[];
      final tracker = ContinuousActivityTracker(
        trackerPort: port,
        sampleInterval: const Duration(seconds: 3),
        onSample: (now, durationMs, appName, category, sampleTitle) async {
          samples.add({
            'now': now,
            'durationMs': durationMs,
            'appName': appName,
            'category': category,
            'sampleTitle': sampleTitle,
          });
        },
      );

      final t1 = DateTime.utc(2026, 11, 1, 10, 0, 0);
      final t2 = DateTime.utc(2026, 11, 1, 10, 0, 3);

      tracker.start(now: t1);
      expect(tracker.isRunning, isTrue);

      await tracker.tick(now: t2);

      expect(samples.length, equals(1));
      expect(samples.first['appName'], equals('VS Code'));
      expect(samples.first['category'], equals('Development'));
      expect(samples.first['durationMs'], equals(3000));

      tracker.stop();
      expect(tracker.isRunning, isFalse);
    });

    test('pruneOldData invokes onPrune with 24 hour cutoff', () async {
      DateTime? prunedCutoff;
      final tracker = ContinuousActivityTracker(
        trackerPort: MockTrackerPort(),
        onSample: (_, __, ___, ____, _____) async {},
        onPrune: (cutoff) async {
          prunedCutoff = cutoff;
        },
      );

      final now = DateTime.utc(2026, 11, 1, 12, 0, 0);
      await tracker.pruneOldData(now: now);

      expect(prunedCutoff, equals(DateTime.utc(2026, 10, 31, 12, 0, 0)));
    });

    test('tick gracefully catches exceptions during sampling without throwing', () async {
      final port = MockTrackerPort();
      final tracker = ContinuousActivityTracker(
        trackerPort: port,
        onSample: (_, __, ___, ____, _____) async => throw Exception('sample failed'),
      );

      final t1 = DateTime.utc(2026, 11, 1, 10, 0, 0);
      final t2 = DateTime.utc(2026, 11, 1, 10, 0, 3);
      port.sample = ActiveAppSample(
        rawClass: 'code',
        rawTitle: 'main.dart',
        sampledAt: t2,
      );

      tracker.start(now: t1);
      // tick should catch the exception silently
      await expectLater(tracker.tick(now: t2), completes);
      tracker.stop();
    });
  });
}
