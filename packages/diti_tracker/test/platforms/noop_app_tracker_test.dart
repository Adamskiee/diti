import 'package:test/test.dart';
import 'package:diti_tracker/diti_tracker.dart';

void main() {
  group('NoopAppTracker', () {
    test('sampleActiveWindow returns null', () async {
      const tracker = NoopAppTracker();
      final sample = await tracker.sampleActiveWindow();
      expect(sample, isNull);
    });
  });
}
