import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:diti/src/features/timer/presentation/widgets/session_summary_card.dart';

void main() {
  group('SessionSummaryCard', () {
    testWidgets('defaults to collapsed and toggles expand/collapse',
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

      // Card header is visible
      expect(find.byKey(const Key('session_summary_card')), findsOneWidget);
      expect(find.text('Session Summary'), findsOneWidget);
      expect(find.byIcon(Icons.query_stats), findsOneWidget);

      // Collapsed by default: metrics are not visible
      expect(find.byIcon(Icons.expand_more), findsOneWidget);
      expect(find.byIcon(Icons.expand_less), findsNothing);
      expect(find.text('Total'), findsNothing);
      expect(find.text('Focus'), findsNothing);
      expect(find.text('Rest'), findsNothing);
      expect(find.text('01:01:05'), findsNothing);

      // Tap toggle button to expand
      final toggleButton =
          find.byKey(const Key('session_summary_toggle_button'));
      expect(toggleButton, findsOneWidget);
      await tester.tap(toggleButton);
      await tester.pumpAndSettle();

      // Expanded: metrics are visible and chevron changes
      expect(find.byIcon(Icons.expand_more), findsNothing);
      expect(find.byIcon(Icons.expand_less), findsOneWidget);
      expect(find.text('Total'), findsOneWidget);
      expect(find.text('Focus'), findsOneWidget);
      expect(find.text('Rest'), findsOneWidget);
      expect(find.text('01:01:05'), findsOneWidget);
      expect(find.text('50:00'), findsOneWidget);
      expect(find.text('11:05'), findsOneWidget);
      expect(find.byIcon(Icons.timer_outlined), findsOneWidget);
      expect(find.byIcon(Icons.bolt_outlined), findsOneWidget);
      expect(find.byIcon(Icons.self_improvement_outlined), findsOneWidget);

      // Tap header to collapse
      await tester.tap(find.text('Session Summary'));
      await tester.pumpAndSettle();

      // Collapsed again
      expect(find.byIcon(Icons.expand_more), findsOneWidget);
      expect(find.byIcon(Icons.expand_less), findsNothing);
      expect(find.text('Total'), findsNothing);
      expect(find.text('Focus'), findsNothing);
      expect(find.text('Rest'), findsNothing);
    });

    testWidgets('renders expanded when initiallyExpanded is true',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SessionSummaryCard(
              initiallyExpanded: true,
              totalSessionElapsedMs: 0,
              totalFocusElapsedMs: 0,
              totalRestElapsedMs: 0,
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.expand_less), findsOneWidget);
      expect(find.text('Total'), findsOneWidget);
      expect(find.text('00:00'), findsNWidgets(3));
    });
  });
}
