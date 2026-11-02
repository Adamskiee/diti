import 'package:flutter_test/flutter_test.dart';
import 'package:diti/src/core/theme/responsive_layout.dart';

void main() {
  group('ResponsiveBreakpoints', () {
    test('defines correct Material 3 expanded and maxContentWidth constants',
        () {
      expect(ResponsiveBreakpoints.expanded, equals(840.0));
      expect(ResponsiveBreakpoints.maxContentWidth, equals(1200.0));
    });
  });
}
