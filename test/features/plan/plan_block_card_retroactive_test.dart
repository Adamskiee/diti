import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:diti/src/features/plan/presentation/widgets/plan_block_card.dart';
import 'package:diti_database/diti_database.dart';

void main() {
  group('PlanBlockCard retroactive entry point', () {
    testWidgets('renders Record Past Session action for scheduled block and triggers callback',
        (tester) async {
      var recorded = false;
      final block = PlanBlock(
        id: 'block-retro-1',
        planDate: '2026-10-16',
        scheduledStartUtc: DateTime.utc(2026, 10, 16, 14, 0),
        timezoneId: 'UTC',
        plannedDurationMs: 1800000,
        routineId: 'Workout',
        status: PlanBlockStatus.scheduled,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PlanBlockCard(
              block: block,
              onStart: () {},
              onEdit: () {},
              onDelete: () {},
              onRecordPastSession: () => recorded = true,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final recordBtn = find.byTooltip('Record Past Session');
      expect(recordBtn, findsOneWidget);

      await tester.tap(recordBtn);
      await tester.pumpAndSettle();

      expect(recorded, isTrue);
    });

    testWidgets('does not render Record Past Session action for completed block',
        (tester) async {
      final block = PlanBlock(
        id: 'block-retro-2',
        planDate: '2026-10-16',
        scheduledStartUtc: DateTime.utc(2026, 10, 16, 14, 0),
        timezoneId: 'UTC',
        plannedDurationMs: 1800000,
        routineId: 'Workout',
        status: PlanBlockStatus.completed,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PlanBlockCard(
              block: block,
              onStart: () {},
              onEdit: () {},
              onDelete: () {},
              onRecordPastSession: () {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byTooltip('Record Past Session'), findsNothing);
    });
  });
}
