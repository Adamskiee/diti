import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:diti_tracker/diti_tracker.dart';

final appTrackerPortProvider = Provider<AppTrackerPort>((ref) {
  if (Platform.isLinux) {
    return LinuxX11AppTracker();
  }
  return const NoopAppTracker();
});

final sessionAppTrackerProvider = Provider<SessionAppTracker>((ref) {
  final port = ref.watch(appTrackerPortProvider);
  final tracker = SessionAppTracker(trackerPort: port);
  ref.onDispose(() {
    tracker.stopSession();
  });
  return tracker;
});
