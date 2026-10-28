import '../domain/active_app_sample.dart';

abstract class AppTrackerPort {
  Future<ActiveAppSample?> sampleActiveWindow();
}
