import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:diti/src/features/history/domain/analytics_models.dart';
import 'package:diti/src/features/history/presentation/widgets/activity_breakdown_card.dart';

void main() {
  testWidgets('ActivityBreakdownCard renders nothing when breakdowns is empty', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: ActivityBreakdownCard(breakdowns: []),
        ),
      ),
    );

    expect(find.text('Activity Breakdown'), findsNothing);
  });

  testWidgets('ActivityBreakdownCard renders breakdown items and percentages', (tester) async {
    final breakdowns = [
      const ActivityBreakdown(
        routineName: 'Deep Work',
        totalDurationMs: 3600000,
        percentage: 0.75,
        color: Colors.blue,
      ),
      const ActivityBreakdown(
        routineName: 'Reading',
        totalDurationMs: 1200000,
        percentage: 0.25,
        color: Colors.orange,
      ),
    ];

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ActivityBreakdownCard(breakdowns: breakdowns),
        ),
      ),
    );

    expect(find.text('Activity Breakdown'), findsOneWidget);
    expect(find.textContaining('Deep Work (75% · 01:00:00)'), findsOneWidget);
    expect(find.textContaining('Reading (25% · 20:00)'), findsOneWidget);
  });
}
