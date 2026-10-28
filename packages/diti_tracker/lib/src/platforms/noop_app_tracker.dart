import '../domain/active_app_sample.dart';
import '../ports/app_tracker_port.dart';

class NoopAppTracker implements AppTrackerPort {
  const NoopAppTracker();

  @override
  Future<ActiveAppSample?> sampleActiveWindow() async => null;
}
