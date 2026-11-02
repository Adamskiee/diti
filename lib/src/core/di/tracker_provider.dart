import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:diti_database/diti_database.dart';
import 'package:diti_tracker/diti_tracker.dart';
import 'repositories_provider.dart';

final appTrackerPortProvider = Provider<AppTrackerPort>((ref) {
  if (Platform.environment.containsKey('FLUTTER_TEST')) {
    return const NoopAppTracker();
  }
  if (Platform.isLinux) {
    return LinuxX11AppTracker();
  }
  return const NoopAppTracker();
});

final sessionAppTrackerProvider = Provider<SessionAppTracker>((ref) {
  final port = ref.watch(appTrackerPortProvider);
  final tracker = SessionAppTracker(
    trackerPort: port,
    minTrackedDuration: const Duration(seconds: 5),
  );
  ref.onDispose(() {
    tracker.stopSession();
  });
  return tracker;
});

final continuousActivityTrackerProvider =
    Provider<ContinuousActivityTracker>((ref) {
  final port = ref.watch(appTrackerPortProvider);
  final repo = ref.watch(activityJournalRepositoryProvider);

  final tracker = ContinuousActivityTracker(
    trackerPort: port,
    onSample: (sampledAtUtc, durationMs, appName, category, sampleTitle) async {
      await repo.recordSample(
        ActivitySampleRecord(
          id: const Uuid().v4(),
          sampledAtUtc: sampledAtUtc,
          durationMs: durationMs,
          appName: appName,
          category: category,
          sampleTitle: sampleTitle,
        ),
      );
    },
    onPrune: (cutoffUtc) async {
      await repo.pruneOlderThan(cutoffUtc);
    },
  );
  ref.onDispose(() {
    tracker.stop();
  });
  return tracker;
});
