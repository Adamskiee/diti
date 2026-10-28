import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:diti_tracker/diti_tracker.dart';
import 'package:diti/src/features/history/presentation/widgets/session_app_breakdown_card.dart';

void main() {
  testWidgets('renders tracked apps with durations and icons', (tester) async {
    final usages = [
      const AppUsageSummary(
        appName: 'Terminal',
        category: 'Terminal',
        durationMs: 1200000, // 20m
      ),
      const AppUsageSummary(
        appName: 'Google Chrome',
        category: 'YouTube',
        sampleTitle: 'YouTube',
        durationMs: 600000, // 10m
      ),
    ];

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SessionAppBreakdownCard(
            usages: usages,
            totalDurationMs: 1800000,
          ),
        ),
      ),
    );

    expect(find.text('Tracked Activity'), findsOneWidget);
    expect(find.text('Terminal'), findsOneWidget);
    expect(find.text('YouTube'), findsOneWidget);
    expect(find.text('20:00'), findsOneWidget);
    expect(find.text('10:00'), findsOneWidget);

    final indicators = tester.widgetList<LinearProgressIndicator>(
      find.byType(LinearProgressIndicator),
    ).toList();
    expect(indicators, hasLength(2));
    expect(indicators[0].value, closeTo(1200000 / 1800000, 0.001));
    expect(indicators[1].value, closeTo(600000 / 1800000, 0.001));
  });

  testWidgets('renders category icons and falls back to apps icon', (tester) async {
    final usages = [
      const AppUsageSummary(
        appName: 'VS Code',
        category: 'Development',
        durationMs: 300000,
      ),
      const AppUsageSummary(
        appName: 'Firefox',
        category: 'Browser',
        durationMs: 300000,
      ),
      const AppUsageSummary(
        appName: 'Notion',
        category: 'Productivity',
        durationMs: 300000,
      ),
      const AppUsageSummary(
        appName: 'Unknown Tool',
        category: 'Other',
        durationMs: 300000,
      ),
    ];

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SessionAppBreakdownCard(
            usages: usages,
            totalDurationMs: 1200000,
          ),
        ),
      ),
    );

    expect(find.byIcon(Icons.code), findsOneWidget);
    expect(find.byIcon(Icons.public), findsOneWidget);
    expect(find.byIcon(Icons.edit_note), findsOneWidget);
    expect(find.byIcon(Icons.apps), findsOneWidget);
  });

  testWidgets('renders nothing when usages is empty', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SessionAppBreakdownCard(
            usages: [],
            totalDurationMs: 1800000,
          ),
        ),
      ),
    );

    expect(find.text('Tracked Activity'), findsNothing);
  });
}
