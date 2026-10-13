import 'cancelable_token.dart';

abstract interface class MonotonicClock {
  int get nowMs;
  CancelableToken schedule(Duration delay, void Function() callback);
}
