import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:diti/src/features/history/presentation/widgets/manual_session_sheet.dart';
import 'package:diti_database/diti_database.dart';
import 'package:diti/src/core/di/repositories_provider.dart';

class StubSessionRepo implements SessionRepository {
  SessionRecord? savedSession;

  @override
  Future<void> saveSession(SessionRecord s) async {
    savedSession = s;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class StubJournalRepo implements ActivityJournalRepository {
  final List<ActivityUsageSummaryRecord> usages;

  StubJournalRepo({
    this.usages = const [
      ActivityUsageSummaryRecord(
        appName: 'Visual Studio Code',
        category: 'Development',
        durationMs: 1800000,
      ),
    ],
  });

  @override
  Future<List<ActivityUsageSummaryRecord>> aggregateUsageBetween(
          DateTime s, DateTime e) async =>
      usages;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class StubPlanRepo implements PlanBlockRepository {
  @override
  Future<List<PlanBlock>> getBlocksForDate(String d) async => [];

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  testWidgets('ManualSessionSheet displays activity fields and detected apps',
      (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sessionRepositoryProvider.overrideWithValue(StubSessionRepo()),
          activityJournalRepositoryProvider
              .overrideWithValue(StubJournalRepo()),
          planBlockRepositoryProvider.overrideWithValue(StubPlanRepo()),
        ],
        child: const MaterialApp(
          home: Scaffold(
            body: ManualSessionSheet(initialRoutineName: 'Sprint Work'),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Record Past Session'), findsOneWidget);
    expect(find.widgetWithText(TextFormField, 'Sprint Work'), findsOneWidget);
    expect(find.text('Visual Studio Code'), findsOneWidget);
    expect(find.text('Save Session'), findsOneWidget);
  });

  testWidgets('ManualSessionSheet shows message when no detected apps',
      (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sessionRepositoryProvider.overrideWithValue(StubSessionRepo()),
          activityJournalRepositoryProvider
              .overrideWithValue(StubJournalRepo(usages: const [])),
          planBlockRepositoryProvider.overrideWithValue(StubPlanRepo()),
        ],
        child: const MaterialApp(
          home: Scaffold(
            body: ManualSessionSheet(initialRoutineName: 'Deep Reading'),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(
        find.text(
            'No background application activity detected in this time range.'),
        findsOneWidget);
  });

  testWidgets(
      'ManualSessionSheet displays validation error when saving without activity name',
      (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sessionRepositoryProvider.overrideWithValue(StubSessionRepo()),
          activityJournalRepositoryProvider
              .overrideWithValue(StubJournalRepo()),
          planBlockRepositoryProvider.overrideWithValue(StubPlanRepo()),
        ],
        child: const MaterialApp(
          home: Scaffold(
            body: ManualSessionSheet(initialRoutineName: ''),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Tap Save Session button
    await tester.tap(find.text('Save Session'));
    await tester.pumpAndSettle();

    expect(find.text('Please enter an activity name.'), findsOneWidget);
  });

  testWidgets('ManualSessionSheet saves session and closes on save button',
      (tester) async {
    final sessionRepo = StubSessionRepo();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sessionRepositoryProvider.overrideWithValue(sessionRepo),
          activityJournalRepositoryProvider
              .overrideWithValue(StubJournalRepo()),
          planBlockRepositoryProvider.overrideWithValue(StubPlanRepo()),
        ],
        child: MaterialApp(
          home: Builder(
            builder: (ctx) => Scaffold(
              body: ElevatedButton(
                onPressed: () {
                  showModalBottomSheet<void>(
                    context: ctx,
                    isScrollControlled: true,
                    builder: (_) => const ManualSessionSheet(
                        initialRoutineName: 'Sprint Review'),
                  );
                },
                child: const Text('Open Sheet'),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open Sheet'));
    await tester.pumpAndSettle();

    expect(find.text('Record Past Session'), findsOneWidget);

    await tester.tap(find.text('Save Session'));
    await tester.pumpAndSettle();

    // The modal bottom sheet should have closed
    expect(find.text('Record Past Session'), findsNothing);
    expect(sessionRepo.savedSession, isNotNull);
    expect(sessionRepo.savedSession!.routineName, equals('Sprint Review'));
  });

  testWidgets('ManualSessionSheet closes on cancel button', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sessionRepositoryProvider.overrideWithValue(StubSessionRepo()),
          activityJournalRepositoryProvider
              .overrideWithValue(StubJournalRepo()),
          planBlockRepositoryProvider.overrideWithValue(StubPlanRepo()),
        ],
        child: MaterialApp(
          home: Builder(
            builder: (ctx) => Scaffold(
              body: ElevatedButton(
                onPressed: () {
                  showModalBottomSheet<void>(
                    context: ctx,
                    isScrollControlled: true,
                    builder: (_) => const ManualSessionSheet(
                        initialRoutineName: 'Sprint Review'),
                  );
                },
                child: const Text('Open Sheet'),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open Sheet'));
    await tester.pumpAndSettle();

    expect(find.text('Record Past Session'), findsOneWidget);

    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    expect(find.text('Record Past Session'), findsNothing);
  });
}
