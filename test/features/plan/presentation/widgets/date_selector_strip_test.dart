import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:diti/src/core/di/database_provider.dart';
import 'package:diti/src/features/plan/presentation/widgets/date_selector_strip.dart';
import 'package:diti/src/features/plan/providers/plan_providers.dart';
import 'package:diti_database/diti_database.dart';

import '../../../../helpers/test_fakes.dart';

void main() {
  group('DateSelectorStrip', () {
    late DitiDatabase db;

    setUp(() {
      db = createInMemoryTestDatabase();
    });

    tearDown(() async {
      await db.close();
    });

    testWidgets('renders day navigation and updates selected date on next day',
        (tester) async {
      final container = ProviderContainer(
        overrides: [
          databaseProvider.overrideWithValue(db),
          selectedDateProvider.overrideWith((ref) => DateTime(2026, 10, 16)),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: Scaffold(
              body: DateSelectorStrip(
                totalPlannedMs: 7200000, // 2h
                totalActualMs: 3600000, // 1h
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Planned: 2h 00m · Done: 1h 00m'), findsOneWidget);

      // Tap next day arrow
      await tester.tap(find.byKey(const Key('date_nav_next')));
      await tester.pumpAndSettle();

      expect(container.read(selectedDateStringProvider), '2026-10-17');
    });

    testWidgets('updates selected date on previous day', (tester) async {
      final container = ProviderContainer(
        overrides: [
          databaseProvider.overrideWithValue(db),
          selectedDateProvider.overrideWith((ref) => DateTime(2026, 10, 16)),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: Scaffold(
              body: DateSelectorStrip(
                totalPlannedMs: 3600000,
                totalActualMs: 1800000,
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Tap previous day arrow
      await tester.tap(find.byKey(const Key('date_nav_prev')));
      await tester.pumpAndSettle();

      expect(container.read(selectedDateStringProvider), '2026-10-15');
    });

    testWidgets(
        'shows Today action chip when selected date is not today, tapping sets today',
        (tester) async {
      final notToday = DateTime(2020, 1, 1);
      final container = ProviderContainer(
        overrides: [
          databaseProvider.overrideWithValue(db),
          selectedDateProvider.overrideWith((ref) => notToday),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: Scaffold(
              body: DateSelectorStrip(
                totalPlannedMs: 0,
                totalActualMs: 0,
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      final todayChip = find.widgetWithText(ActionChip, 'Today');
      expect(todayChip, findsOneWidget);

      await tester.tap(todayChip);
      await tester.pumpAndSettle();

      final now = DateTime.now();
      final expectedDateStr =
          '${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
      expect(container.read(selectedDateStringProvider), expectedDateStr);
    });

    testWidgets('does not show Today action chip when selected date is today',
        (tester) async {
      final today = DateTime.now();
      final container = ProviderContainer(
        overrides: [
          databaseProvider.overrideWithValue(db),
          selectedDateProvider.overrideWith((ref) => today),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: Scaffold(
              body: DateSelectorStrip(
                totalPlannedMs: 0,
                totalActualMs: 0,
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.widgetWithText(ActionChip, 'Today'), findsNothing);
    });

    testWidgets(
        'tapping date label opens date picker and selecting date updates selection',
        (tester) async {
      final initialDate = DateTime(2026, 10, 16);
      final container = ProviderContainer(
        overrides: [
          databaseProvider.overrideWithValue(db),
          selectedDateProvider.overrideWith((ref) => initialDate),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: Scaffold(
              body: DateSelectorStrip(
                totalPlannedMs: 0,
                totalActualMs: 0,
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Tap on the date label area (InkWell between chevron_left and chevron_right)
      await tester.tap(find.byKey(const Key('date_picker_button')));
      await tester.pumpAndSettle();

      // DatePicker should be visible
      expect(find.byType(DatePickerDialog), findsOneWidget);

      // Select day 20
      await tester.tap(find.text('20'));
      await tester.pumpAndSettle();

      // Tap OK
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();

      expect(container.read(selectedDateStringProvider), '2026-10-20');
    });
  });
}
