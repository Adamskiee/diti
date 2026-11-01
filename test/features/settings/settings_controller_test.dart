import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:diti/src/features/settings/presentation/controllers/settings_controller.dart';

void main() {
  test('continuous tracking defaults to true and can be toggled', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    expect(container.read(continuousTrackingEnabledProvider), isTrue);

    container.read(continuousTrackingEnabledProvider.notifier).toggle(false);
    expect(container.read(continuousTrackingEnabledProvider), isFalse);

    container.read(continuousTrackingEnabledProvider.notifier).toggle(true);
    expect(container.read(continuousTrackingEnabledProvider), isTrue);
  });
}
