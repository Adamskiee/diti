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
        focusDurationMs: 60 * 60 * 1000,
        restDurationMs: 0,
        sessionCount: 1,
      ),
      DailyBucket(
        date: DateTime(2026, 10, 13),
        dayLabel: 'Tue',
        totalDurationMs: 0,
        focusDurationMs: 0,
        restDurationMs: 0,
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
        focusDurationMs: 3600000,
        restDurationMs: 0,
        sessionCount: 1,
      ),
      DailyBucket(
        date: DateTime(2026, 10, 13),
        dayLabel: 'Tue',
        totalDurationMs: 1800000,
        focusDurationMs: 1800000,
        restDurationMs: 0,
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

  testWidgets('renders a stacked bar with a focus and rest legend', (tester) async {
    final buckets = [
      DailyBucket(
        date: DateTime(2026, 10, 12),
        dayLabel: 'Mon',
        totalDurationMs: 30 * 60 * 1000,
        focusDurationMs: 25 * 60 * 1000,
        restDurationMs: 5 * 60 * 1000,
        sessionCount: 1,
      ),
    ];

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: FocusBarChartWidget(buckets: buckets),
        ),
      ),
    );

    expect(find.text('Focus & Rest Activity'), findsOneWidget);
    expect(find.text('Focus'), findsOneWidget);
    expect(find.text('Rest'), findsOneWidget);

    final focusSegment = find.byKey(const ValueKey('focus-segment'));
    final restSegment = find.byKey(const ValueKey('rest-segment'));
    expect(focusSegment, findsOneWidget);
    expect(restSegment, findsOneWidget);

    // The focus segment sits below the rest segment and is the taller of the two.
    final focusRect = tester.getRect(focusSegment);
    final restRect = tester.getRect(restSegment);
    expect(focusRect.top, greaterThan(restRect.top));
    expect(focusRect.height, greaterThan(restRect.height));
  });

  testWidgets('a bucket with no rest time renders a single segment', (tester) async {
    final buckets = [
      DailyBucket(
        date: DateTime(2026, 10, 12),
        dayLabel: 'Mon',
        totalDurationMs: 60 * 60 * 1000,
        focusDurationMs: 60 * 60 * 1000,
        restDurationMs: 0,
        sessionCount: 1,
      ),
    ];

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: FocusBarChartWidget(buckets: buckets),
        ),
      ),
    );

    expect(find.byKey(const ValueKey('focus-segment')), findsOneWidget);
    expect(find.byKey(const ValueKey('rest-segment')), findsNothing);
  });

  testWidgets('the selection readout splits focus and rest when rest is non-zero', (tester) async {
    final buckets = [
      DailyBucket(
        date: DateTime(2026, 10, 12),
        dayLabel: 'Mon',
        totalDurationMs: 30 * 60 * 1000,
        focusDurationMs: 25 * 60 * 1000,
        restDurationMs: 5 * 60 * 1000,
        sessionCount: 1,
      ),
    ];

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: FocusBarChartWidget(buckets: buckets),
        ),
      ),
    );

    await tester.tap(find.text('Mon'));
    await tester.pump();

    expect(find.textContaining('25:00'), findsOneWidget);
    expect(find.textContaining('05:00'), findsOneWidget);
    expect(find.textContaining('30:00'), findsNothing);
  });
}
