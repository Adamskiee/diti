import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:diti/src/core/theme/app_colors.dart';
import 'package:diti/src/features/plan/domain/plan_block_conflict.dart';
import 'package:diti/src/features/plan/presentation/widgets/conflict_warning_banner.dart';
import 'package:diti/src/features/plan/presentation/widgets/plan_block_card.dart';
import 'package:diti_database/diti_database.dart';
import 'package:intl/intl.dart';

void main() {
  Widget buildSubject({
    required PlanBlock block,
    List<PlanBlockConflict> conflicts = const [],
    VoidCallback? onStart,
    VoidCallback? onEdit,
    VoidCallback? onDelete,
  }) {
    return MaterialApp(
      home: Scaffold(
        body: PlanBlockCard(
          block: block,
          conflicts: conflicts,
          onStart: onStart ?? () {},
          onEdit: onEdit ?? () {},
          onDelete: onDelete ?? () {},
        ),
      ),
    );
  }

  group('PlanBlockCard', () {
    testWidgets(
        'renders times with tabular figures, status, conflict warning, and overrun',
        (tester) async {
      final startUtc = DateTime.utc(2026, 10, 16, 9, 0);
      final block = PlanBlock(
        id: 'b1',
        planDate: '2026-10-16',
        scheduledStartUtc: startUtc,
        timezoneId: 'UTC',
        plannedDurationMs: 3000000, // 50m
        actualDurationMs: 3300000, // 55m (+5m overrun)
        routineId: 'Deep Focus',
        status: PlanBlockStatus.completed,
      );

      final conflict = PlanBlockConflict(
        blockId: 'b1',
        conflictingBlockId: 'b2',
        conflictingTitle: 'Meeting',
        conflictingStartUtc: DateTime.utc(2026, 10, 16, 9, 30),
        conflictingEndUtc: DateTime.utc(2026, 10, 16, 10, 30),
        description: 'Overlaps with Meeting (09:30 - 10:30)',
      );

      await tester.pumpWidget(
        buildSubject(
          block: block,
          conflicts: [conflict],
        ),
      );
      await tester.pumpAndSettle();

      final timeFormat = DateFormat.jm();
      final expectedStart = timeFormat.format(startUtc.toLocal());
      final expectedEnd = timeFormat.format(
          startUtc.toLocal().add(const Duration(milliseconds: 3000000)));

      expect(find.text('Deep Focus'), findsOneWidget);
      expect(find.text(expectedStart), findsOneWidget);
      expect(find.text(expectedEnd), findsOneWidget);

      final startTimeText = tester.widget<Text>(find.text(expectedStart));
      expect(
        startTimeText.style?.fontFeatures,
        contains(const FontFeature.tabularFigures()),
      );

      final endTimeText = tester.widget<Text>(find.text(expectedEnd));
      expect(
        endTimeText.style?.fontFeatures,
        contains(const FontFeature.tabularFigures()),
      );

      expect(find.textContaining('Completed'), findsOneWidget);
      expect(find.textContaining('Planned: 50m'), findsOneWidget);
      expect(find.textContaining('Actual: 55m'), findsOneWidget);
      expect(find.textContaining('+5m overrun'), findsOneWidget);
      expect(find.textContaining('Overlaps with Meeting'), findsOneWidget);
      expect(find.byType(ConflictWarningBanner), findsOneWidget);
    });

    testWidgets(
        'renders scheduled block with Start Block action and invokes callback',
        (tester) async {
      var started = false;
      final block = PlanBlock(
        id: 'b2',
        planDate: '2026-10-16',
        scheduledStartUtc: DateTime.utc(2026, 10, 16, 14, 0),
        timezoneId: 'UTC',
        plannedDurationMs: 1800000, // 30m
        routineId: 'Quick Review',
        status: PlanBlockStatus.scheduled,
      );

      await tester.pumpWidget(
        buildSubject(
          block: block,
          onStart: () => started = true,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Scheduled'), findsOneWidget);
      expect(find.text('Start Block'), findsOneWidget);
      expect(find.byIcon(Icons.play_arrow), findsOneWidget);

      await tester.tap(find.text('Start Block'));
      await tester.pumpAndSettle();

      expect(started, isTrue);
    });

    testWidgets(
        'renders inProgress block with View Active Timer action and invokes callback',
        (tester) async {
      var started = false;
      final block = PlanBlock(
        id: 'b3',
        planDate: '2026-10-16',
        scheduledStartUtc: DateTime.utc(2026, 10, 16, 10, 0),
        timezoneId: 'UTC',
        plannedDurationMs: 1800000,
        status: PlanBlockStatus.inProgress,
      );

      await tester.pumpWidget(
        buildSubject(
          block: block,
          onStart: () => started = true,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Custom Activity'), findsOneWidget);
      expect(find.text('In Progress'), findsOneWidget);
      expect(find.text('View Active Timer'), findsOneWidget);
      expect(find.byIcon(Icons.timer), findsOneWidget);

      await tester.tap(find.text('View Active Timer'));
      await tester.pumpAndSettle();

      expect(started, isTrue);
    });

    testWidgets('renders under time difference tag in successGreen',
        (tester) async {
      final block = PlanBlock(
        id: 'b4',
        planDate: '2026-10-16',
        scheduledStartUtc: DateTime.utc(2026, 10, 16, 11, 0),
        timezoneId: 'UTC',
        plannedDurationMs: 3600000, // 1h
        actualDurationMs: 2400000, // 40m (-20m under)
        routineId: 'Reading',
        status: PlanBlockStatus.completed,
      );

      await tester.pumpWidget(buildSubject(block: block));
      await tester.pumpAndSettle();

      expect(find.textContaining('20m under'), findsOneWidget);
      final tagWidget = tester.widget<Text>(find.text('20m under'));
      expect(tagWidget.style?.color, AppColors.successGreen);
    });

    testWidgets(
        'renders on target time difference tag when difference is within 1 minute',
        (tester) async {
      final block = PlanBlock(
        id: 'b5',
        planDate: '2026-10-16',
        scheduledStartUtc: DateTime.utc(2026, 10, 16, 11, 0),
        timezoneId: 'UTC',
        plannedDurationMs: 1800000, // 30m
        actualDurationMs: 1830000, // 30m 30s (+30s)
        routineId: 'Writing',
        status: PlanBlockStatus.completed,
      );

      await tester.pumpWidget(buildSubject(block: block));
      await tester.pumpAndSettle();

      expect(find.text('on target'), findsOneWidget);
      final tagWidget = tester.widget<Text>(find.text('on target'));
      expect(tagWidget.style?.color, AppColors.successGreen);
    });

    testWidgets('renders cancelled status chip', (tester) async {
      final block = PlanBlock(
        id: 'b6',
        planDate: '2026-10-16',
        scheduledStartUtc: DateTime.utc(2026, 10, 16, 11, 0),
        timezoneId: 'UTC',
        plannedDurationMs: 1800000,
        routineId: 'Cancelled Task',
        status: PlanBlockStatus.cancelled,
      );

      await tester.pumpWidget(buildSubject(block: block));
      await tester.pumpAndSettle();

      expect(find.text('Cancelled'), findsOneWidget);
    });

    testWidgets('popup menu handles edit and delete actions', (tester) async {
      var edited = false;
      var deleted = false;
      final block = PlanBlock(
        id: 'b7',
        planDate: '2026-10-16',
        scheduledStartUtc: DateTime.utc(2026, 10, 16, 15, 0),
        timezoneId: 'UTC',
        plannedDurationMs: 1800000,
        routineId: 'Task with Menu',
        status: PlanBlockStatus.scheduled,
      );

      await tester.pumpWidget(
        buildSubject(
          block: block,
          onEdit: () => edited = true,
          onDelete: () => deleted = true,
        ),
      );
      await tester.pumpAndSettle();

      // Open popup menu
      await tester.tap(find.byIcon(Icons.more_vert));
      await tester.pumpAndSettle();

      expect(find.text('Edit'), findsOneWidget);
      expect(find.text('Delete'), findsOneWidget);

      await tester.tap(find.text('Edit'));
      await tester.pumpAndSettle();
      expect(edited, isTrue);

      // Open popup menu again for Delete
      await tester.tap(find.byIcon(Icons.more_vert));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Delete'));
      await tester.pumpAndSettle();
      expect(deleted, isTrue);
    });
  });
}
