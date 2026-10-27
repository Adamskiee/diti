import 'package:test/test.dart';
import 'package:diti_tracker/diti_tracker.dart';

class StubAppTracker implements AppTrackerPort {
  ActiveAppSample? currentSample;
  @override
  Future<ActiveAppSample?> sampleActiveWindow() async => currentSample;
}

void main() {
  group('SessionAppTracker', () {
    late StubAppTracker stub;
    late SessionAppTracker tracker;

    setUp(() {
      stub = StubAppTracker();
      tracker = SessionAppTracker(
        trackerPort: stub,
        sampleInterval: const Duration(seconds: 2),
      );
    });

    test('accumulates time across multiple ticks for the same app', () async {
      stub.currentSample = ActiveAppSample(
        rawClass: 'alacritty',
        rawTitle: 'bash',
        sampledAt: DateTime.utc(2026, 10, 26, 10, 0, 0),
      );

      tracker.startSession('session-1');
      await tracker.tick(now: DateTime.utc(2026, 10, 26, 10, 0, 0));
      await tracker.tick(now: DateTime.utc(2026, 10, 26, 10, 0, 2));
      await tracker.tick(now: DateTime.utc(2026, 10, 26, 10, 0, 4));

      final results = await tracker.stopSession();
      expect(results.length, equals(1));
      expect(results.first.appName, equals('Terminal'));
      expect(results.first.category, equals('Terminal'));
      expect(results.first.durationMs, equals(4000));
    });

    test('differentiates YouTube from generic Chrome usage', () async {
      tracker.startSession('session-2');

      // 4 seconds YouTube
      stub.currentSample = ActiveAppSample(
        rawClass: 'google-chrome',
        rawTitle: 'Song - YouTube - Google Chrome',
        sampledAt: DateTime.utc(2026, 10, 26, 10, 0, 0),
      );
      await tracker.tick(now: DateTime.utc(2026, 10, 26, 10, 0, 0));
      await tracker.tick(now: DateTime.utc(2026, 10, 26, 10, 0, 4));

      // 4 seconds VS Code
      stub.currentSample = ActiveAppSample(
        rawClass: 'code',
        rawTitle: 'main.dart - Visual Studio Code',
        sampledAt: DateTime.utc(2026, 10, 26, 10, 0, 4),
      );
      await tracker.tick(now: DateTime.utc(2026, 10, 26, 10, 0, 8));

      final results = await tracker.stopSession();
      expect(results.length, equals(2));

      final youtube = results.firstWhere((r) => r.category == 'YouTube');
      expect(youtube.durationMs, equals(4000));

      final code = results.firstWhere((r) => r.category == 'Development');
      expect(code.appName, equals('VS Code'));
      expect(code.durationMs, equals(4000));
    });

    test('does not accumulate time while paused', () async {
      stub.currentSample = ActiveAppSample(
        rawClass: 'alacritty',
        rawTitle: 'bash',
        sampledAt: DateTime.utc(2026, 10, 26, 10, 0, 0),
      );

      tracker.startSession('session-3');
      await tracker.tick(now: DateTime.utc(2026, 10, 26, 10, 0, 0));
      await tracker.tick(now: DateTime.utc(2026, 10, 26, 10, 0, 2));

      tracker.pauseSession();
      await tracker.tick(now: DateTime.utc(2026, 10, 26, 10, 0, 10));

      tracker.resumeSession();
      await tracker.tick(now: DateTime.utc(2026, 10, 26, 10, 0, 12));

      final results = await tracker.stopSession();
      expect(results.first.durationMs, equals(4000)); // 2s before pause + 2s after resume
    });

    test('caps large sample gap (e.g. system suspend) to sampleInterval', () async {
      stub.currentSample = ActiveAppSample(
        rawClass: 'alacritty',
        rawTitle: 'bash',
        sampledAt: DateTime.utc(2026, 10, 26, 10, 0, 0),
      );

      tracker.startSession('session-4');
      await tracker.tick(now: DateTime.utc(2026, 10, 26, 10, 0, 0));
      // Gap of 60 seconds (> maxSampleGap of 10s default)
      await tracker.tick(now: DateTime.utc(2026, 10, 26, 10, 1, 0));

      final results = await tracker.stopSession();
      expect(results.first.durationMs, equals(2000)); // capped to sampleInterval (2s)
    });

    test('handles null sample without accumulating duration', () async {
      stub.currentSample = ActiveAppSample(
        rawClass: 'alacritty',
        rawTitle: 'bash',
        sampledAt: DateTime.utc(2026, 10, 26, 10, 0, 0),
      );

      tracker.startSession('session-5');
      await tracker.tick(now: DateTime.utc(2026, 10, 26, 10, 0, 0));

      stub.currentSample = null;
      await tracker.tick(now: DateTime.utc(2026, 10, 26, 10, 0, 2));

      final results = await tracker.stopSession();
      expect(results, isEmpty);
    });

    test('prunes transient switches shorter than minTrackedDuration', () async {
      final prunedTracker = SessionAppTracker(
        trackerPort: stub,
        sampleInterval: const Duration(seconds: 2),
        minTrackedDuration: const Duration(seconds: 5),
      );

      // App 1: 6 seconds (persists)
      stub.currentSample = ActiveAppSample(
        rawClass: 'alacritty',
        rawTitle: 'bash',
        sampledAt: DateTime.utc(2026, 10, 26, 10, 0, 0),
      );
      prunedTracker.startSession('session-6');
      await prunedTracker.tick(now: DateTime.utc(2026, 10, 26, 10, 0, 0));
      await prunedTracker.tick(now: DateTime.utc(2026, 10, 26, 10, 0, 6));

      // App 2: 2 seconds (pruned)
      stub.currentSample = ActiveAppSample(
        rawClass: 'spotify',
        rawTitle: 'Spotify',
        sampledAt: DateTime.utc(2026, 10, 26, 10, 0, 6),
      );
      await prunedTracker.tick(now: DateTime.utc(2026, 10, 26, 10, 0, 8));

      final results = await prunedTracker.stopSession();
      expect(results.length, equals(1));
      expect(results.first.appName, equals('Terminal'));
    });
  });
}
