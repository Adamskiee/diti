import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:diti/src/features/history/domain/analytics_models.dart';
import 'package:diti/src/features/history/presentation/widgets/focus_bar_chart_widget.dart';

void main() {
  testWidgets('FocusBarChartWidget renders day labels and handles empty buckets', (tester) async {
    final buckets = [
      DailyBucket(
        date: DateTime(2026, 10, 12),
        dayLabel: 'Mon',
        totalDurationMs: 60 * 60 * 1000,
        sessionCount: 1,
      ),
      DailyBucket(
        date: DateTime(2026, 10, 13),
        dayLabel: 'Tue',
        totalDurationMs: 0,
        sessionCount: 0,
      ),
    ];

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: FocusBarChartWidget(buckets: buckets),
        ),
      ),
    );

    expect(find.text('Mon'), findsOneWidget);
    expect(find.text('Tue'), findsOneWidget);
    expect(find.byType(CustomPaint), findsWidgets);
  });

  testWidgets('FocusBarChartWidget selects bucket on tap and triggers callback', (tester) async {
    DailyBucket? selected;
    final buckets = [
      DailyBucket(
        date: DateTime(2026, 10, 12),
        dayLabel: 'Mon',
        totalDurationMs: 3600000,
        sessionCount: 1,
      ),
      DailyBucket(
        date: DateTime(2026, 10, 13),
        dayLabel: 'Tue',
        totalDurationMs: 1800000,
        sessionCount: 1,
      ),
    ];

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: FocusBarChartWidget(
            buckets: buckets,
            onBucketSelected: (b) => selected = b,
          ),
        ),
      ),
    );

    // Tap Monday
    await tester.tap(find.text('Mon'));
    await tester.pump();

    expect(selected, isNotNull);
    expect(selected!.dayLabel, 'Mon');
    expect(find.textContaining('Mon: 01:00:00'), findsOneWidget);

    // Tap Monday again to deselect
    await tester.tap(find.text('Mon'));
    await tester.pump();
    expect(find.textContaining('Mon: 01:00:00'), findsNothing);
  });
}
