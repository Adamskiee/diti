import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:diti/src/features/timer/presentation/widgets/session_summary_card.dart';

void main() {
  group('SessionSummaryCard', () {
    testWidgets('renders all metric labels and formatted durations',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SessionSummaryCard(
              totalSessionElapsedMs: 3665000, // 01:01:05
              totalFocusElapsedMs: 3000000, // 50:00
              totalRestElapsedMs: 665000, // 11:05
            ),
          ),
        ),
      );

      expect(find.byKey(const Key('session_summary_card')), findsOneWidget);
      expect(find.text('Session Summary'), findsOneWidget);
      expect(find.byIcon(Icons.query_stats), findsOneWidget);

      expect(find.text('Total'), findsOneWidget);
      expect(find.text('Focus'), findsOneWidget);
      expect(find.text('Rest'), findsOneWidget);

      expect(find.text('01:01:05'), findsOneWidget);
      expect(find.text('50:00'), findsOneWidget);
      expect(find.text('11:05'), findsOneWidget);

      expect(find.byIcon(Icons.timer_outlined), findsOneWidget);
      expect(find.byIcon(Icons.bolt_outlined), findsOneWidget);
      expect(find.byIcon(Icons.self_improvement_outlined), findsOneWidget);
    });

    testWidgets('renders zero durations gracefully', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SessionSummaryCard(
              totalSessionElapsedMs: 0,
              totalFocusElapsedMs: 0,
              totalRestElapsedMs: 0,
            ),
          ),
        ),
      );

      expect(find.text('00:00'), findsNWidgets(3));
    });
  });
}
