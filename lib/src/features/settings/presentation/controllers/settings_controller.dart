import 'package:flutter_riverpod/flutter_riverpod.dart';

class ContinuousTrackingEnabledNotifier extends Notifier<bool> {
  @override
  bool build() => true;

  void toggle(bool enabled) {
    state = enabled;
  }
}

final continuousTrackingEnabledProvider =
    NotifierProvider<ContinuousTrackingEnabledNotifier, bool>(
  ContinuousTrackingEnabledNotifier.new,
);
