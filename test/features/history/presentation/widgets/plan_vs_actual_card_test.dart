import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:diti/src/features/history/domain/analytics_models.dart';
import 'package:diti/src/features/history/presentation/widgets/plan_vs_actual_card.dart';

void main() {
  testWidgets('PlanVsActualCard renders overrun correctly', (tester) async {
    const metrics = PlanVersusActualMetrics(
      totalPlannedMs: 3600000, // 01:00:00
      totalActualMs: 4200000, // 01:10:00
      netVarianceMs: 600000, // +10:00
      linkedSessionCount: 2,
    );

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: PlanVsActualCard(metrics: metrics),
        ),
      ),
    );

    expect(find.text('Planned vs Actual'), findsOneWidget);
    expect(find.text('+10:00 overrun'), findsOneWidget);
    expect(find.text('01:00:00'), findsOneWidget);
    expect(find.text('01:10:00'), findsOneWidget);
  });

  testWidgets('PlanVsActualCard renders saved time correctly', (tester) async {
    const metrics = PlanVersusActualMetrics(
      totalPlannedMs: 3600000, // 01:00:00
      totalActualMs: 3000000, // 50:00
      netVarianceMs: -600000, // -10:00
      linkedSessionCount: 2,
    );

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: PlanVsActualCard(metrics: metrics),
        ),
      ),
    );

    expect(find.text('Planned vs Actual'), findsOneWidget);
    expect(find.text('-10:00 saved'), findsOneWidget);
    expect(find.text('01:00:00'), findsOneWidget);
    expect(find.text('50:00'), findsOneWidget);
  });
}
