import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:diti/src/features/history/domain/analytics_models.dart';
import 'package:diti/src/features/history/presentation/widgets/focus_bar_chart_widget.dart';

void main() {
  testWidgets(
      'FocusBarChartWidget renders day labels and handles empty buckets',
      (tester) async {
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

  testWidgets('FocusBarChartWidget selects bucket on tap and triggers callback',
      (tester) async {
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

  testWidgets('renders a stacked bar with a focus and rest legend',
      (tester) async {
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

  testWidgets('a bucket with no rest time renders a single segment',
      (tester) async {
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

  testWidgets('the readout is not painted in the focus colour', (tester) async {
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

    // The readout names the total, the focus and the rest, so no single
    // concept's colour may paint it: it wears the default surface colour,
    // like the chart title, and never the focus colour.
    final theme = Theme.of(tester.element(find.byType(FocusBarChartWidget)));
    final readoutStyle =
        tester.widget<Text>(find.textContaining('30:00 total')).style;
    final titleStyle =
        tester.widget<Text>(find.text('Focus & Rest Activity')).style;

    expect(readoutStyle?.color, isNot(theme.colorScheme.primary));
    expect(readoutStyle?.color, titleStyle?.color);
  });

  testWidgets('the readout names every number and always shows the total',
      (tester) async {
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
          body: FocusBarChartWidget(
            key: const ValueKey('with-rest'),
            buckets: buckets,
          ),
        ),
      ),
    );

    await tester.tap(find.text('Mon'));
    await tester.pump();

    expect(find.textContaining('30:00 total'), findsOneWidget);
    expect(find.textContaining('25:00 focus'), findsOneWidget);
    expect(find.textContaining('05:00 rest'), findsOneWidget);

    // A day without rest still names the total.
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: FocusBarChartWidget(
            key: const ValueKey('without-rest'),
            buckets: [
              DailyBucket(
                date: DateTime(2026, 10, 12),
                dayLabel: 'Mon',
                totalDurationMs: 30 * 60 * 1000,
                focusDurationMs: 30 * 60 * 1000,
                restDurationMs: 0,
                sessionCount: 1,
              ),
            ],
          ),
        ),
      ),
    );

    await tester.tap(find.text('Mon'));
    await tester.pump();

    expect(find.text('Mon: 30:00 total'), findsOneWidget);
  });

  testWidgets('bar heights are normalised against the day total, not its focus',
      (tester) async {
    final buckets = [
      DailyBucket(
        date: DateTime(2026, 10, 12),
        dayLabel: 'Mon',
        totalDurationMs: 60 * 60 * 1000,
        focusDurationMs: 50 * 60 * 1000,
        restDurationMs: 10 * 60 * 1000,
        sessionCount: 1,
      ),
      DailyBucket(
        date: DateTime(2026, 10, 13),
        dayLabel: 'Tue',
        totalDurationMs: 30 * 60 * 1000,
        focusDurationMs: 10 * 60 * 1000,
        restDurationMs: 20 * 60 * 1000,
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

    final monBar = find.ancestor(
      of: find.text('Mon'),
      matching: find.byType(InkWell),
    );
    final tueBar = find.ancestor(
      of: find.text('Tue'),
      matching: find.byType(InkWell),
    );

    final monFocus = find.descendant(
      of: monBar,
      matching: find.byKey(const ValueKey('focus-segment')),
    );
    final monRest = find.descendant(
      of: monBar,
      matching: find.byKey(const ValueKey('rest-segment')),
    );
    final tueFocus = find.descendant(
      of: tueBar,
      matching: find.byKey(const ValueKey('focus-segment')),
    );
    final tueRest = find.descendant(
      of: tueBar,
      matching: find.byKey(const ValueKey('rest-segment')),
    );

    expect(monFocus, findsOneWidget);
    expect(monRest, findsOneWidget);
    expect(tueFocus, findsOneWidget);
    expect(tueRest, findsOneWidget);

    final monHeight =
        tester.getRect(monFocus).height + tester.getRect(monRest).height;
    final tueHeight =
        tester.getRect(tueFocus).height + tester.getRect(tueRest).height;

    // The bar follows the day's total (60m against 30m), not its focus time
    // (50m against 10m), which would make Monday five times as tall.
    expect(monHeight, closeTo(tueHeight * 2, 0.5));

    // The bar's own split follows the day's focus and rest time.
    expect(
      tester.getRect(monFocus).height / monHeight,
      closeTo(50 / 60, 0.01),
    );
    expect(
      tester.getRect(monRest).height / monHeight,
      closeTo(10 / 60, 0.01),
    );
  });

  testWidgets('the legend omits the rest entry when no day has rest',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: FocusBarChartWidget(
            buckets: [
              DailyBucket(
                date: DateTime(2026, 10, 12),
                dayLabel: 'Mon',
                totalDurationMs: 60 * 60 * 1000,
                focusDurationMs: 60 * 60 * 1000,
                restDurationMs: 0,
                sessionCount: 1,
              ),
            ],
          ),
        ),
      ),
    );

    expect(find.text('Focus'), findsOneWidget);
    expect(find.text('Rest'), findsNothing);

    // A set where one day has rest shows both entries.
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: FocusBarChartWidget(
            buckets: [
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
                totalDurationMs: 30 * 60 * 1000,
                focusDurationMs: 25 * 60 * 1000,
                restDurationMs: 5 * 60 * 1000,
                sessionCount: 1,
              ),
            ],
          ),
        ),
      ),
    );

    expect(find.text('Focus'), findsOneWidget);
    expect(find.text('Rest'), findsOneWidget);
  });

  testWidgets('the chart header does not overflow at 320dp', (tester) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

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

    expect(tester.takeException(), isNull);
    expect(find.textContaining('30:00 total'), findsOneWidget);
  });
}
