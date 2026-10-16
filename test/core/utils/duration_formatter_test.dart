import 'package:flutter_test/flutter_test.dart';
import 'package:focus_flow/src/core/utils/duration_formatter.dart';

void main() {
  group('DurationFormatter', () {
    test('formatMs formats under 1 hour as mm:ss', () {
      expect(DurationFormatter.formatMs(0), '00:00');
      expect(DurationFormatter.formatMs(5000), '00:05');
      expect(DurationFormatter.formatMs(65000), '01:05');
      expect(DurationFormatter.formatMs(1500000), '25:00');
    });

    test('formatMs formats 1 hour or more as hh:mm:ss', () {
      expect(DurationFormatter.formatMs(3600000), '01:00:00');
      expect(DurationFormatter.formatMs(3665000), '01:01:05');
    });

    test('formatDurationSummary handles null as Open-ended', () {
      expect(DurationFormatter.formatDurationSummary(null), 'Open-ended');
    });

    test('formatDurationSummary formats minutes and hours cleanly', () {
      expect(DurationFormatter.formatDurationSummary(300000), '5m');
      expect(DurationFormatter.formatDurationSummary(1500000), '25m');
      expect(DurationFormatter.formatDurationSummary(3600000), '1h 00m');
      expect(DurationFormatter.formatDurationSummary(5400000), '1h 30m');
    });
  });
}
