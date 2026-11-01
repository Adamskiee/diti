import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:diti_database/diti_database.dart';
import 'package:diti/src/features/history/domain/manual_session_state.dart';
import 'package:diti/src/features/history/presentation/controllers/manual_session_controller.dart';
import 'package:diti/src/core/di/repositories_provider.dart';

class FakeSessionRepo implements SessionRepository {
  SessionRecord? saved;
  @override
  Future<void> saveSession(SessionRecord s) async { saved = s; }
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakePlanBlockRepo implements PlanBlockRepository {
  PlanBlock? updated;
  @override
  Future<void> updatePlanBlock(PlanBlock b) async { updated = b; }
  @override
  Future<PlanBlock?> getBlockById(String id) async => PlanBlock(
    id: id,
    planDate: '2026-11-01',
    scheduledStartUtc: DateTime.utc(2026, 11, 1, 14, 0),
    timezoneId: 'UTC',
    plannedDurationMs: 1800000,
  );
  Future<PlanBlock?> getPlanBlock(String id) async => getBlockById(id);
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeActivityJournalRepo implements ActivityJournalRepository {
  @override
  Future<List<ActivityUsageSummaryRecord>> aggregateUsageBetween(DateTime s, DateTime e) async => [
    const ActivityUsageSummaryRecord(
      appName: 'VS Code',
      category: 'Development',
      durationMs: 1800000,
    ),
  ];
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  test('ManualSessionController calculates duration bidirectionally and saves session', () async {
    final fakeSessionRepo = FakeSessionRepo();
    final fakePlanRepo = FakePlanBlockRepo();
    final fakeJournal = FakeActivityJournalRepo();

    final container = ProviderContainer(
      overrides: [
        sessionRepositoryProvider.overrideWithValue(fakeSessionRepo),
        planBlockRepositoryProvider.overrideWithValue(fakePlanRepo),
        activityJournalRepositoryProvider.overrideWithValue(fakeJournal),
      ],
    );
    addTearDown(container.dispose);

    final controller = container.read(manualSessionControllerProvider.notifier);
    expect(container.read(manualSessionControllerProvider), isA<ManualSessionState>());

    controller.setDate(DateTime(2026, 11, 1));
    controller.setStartTime(const TimeOfDay(hour: 14, minute: 0));
    controller.setEndTime(const TimeOfDay(hour: 14, minute: 30));

    // Duration should automatically be 30 minutes
    expect(container.read(manualSessionControllerProvider).durationMinutes, equals(30));

    // Changing duration should update end time to 15:00
    controller.setDurationMinutes(60);
    expect(container.read(manualSessionControllerProvider).endTime, equals(const TimeOfDay(hour: 15, minute: 0)));

    controller.setRoutineName('Deep Work');
    controller.setPlanBlockId('block-123');

    final success = await controller.saveSession();
    expect(success, isTrue);

    // Verify session record
    expect(fakeSessionRepo.saved, isNotNull);
    expect(fakeSessionRepo.saved!.routineName, equals('Deep Work'));
    expect(fakeSessionRepo.saved!.totalDurationMs, equals(3600000));
    expect(fakeSessionRepo.saved!.outcome, equals(SessionOutcome.completed));

    // Verify plan block updated to completed
    expect(fakePlanRepo.updated, isNotNull);
    expect(fakePlanRepo.updated!.status, equals(PlanBlockStatus.completed));
    expect(fakePlanRepo.updated!.actualDurationMs, equals(3600000));
  });

  test('ManualSessionController rejects empty routine name', () async {
    final fakeSessionRepo = FakeSessionRepo();
    final fakePlanRepo = FakePlanBlockRepo();
    final fakeJournal = FakeActivityJournalRepo();

    final container = ProviderContainer(
      overrides: [
        sessionRepositoryProvider.overrideWithValue(fakeSessionRepo),
        planBlockRepositoryProvider.overrideWithValue(fakePlanRepo),
        activityJournalRepositoryProvider.overrideWithValue(fakeJournal),
      ],
    );
    addTearDown(container.dispose);

    final controller = container.read(manualSessionControllerProvider.notifier);
    controller.setRoutineName('   ');

    final success = await controller.saveSession();
    expect(success, isFalse);
    expect(container.read(manualSessionControllerProvider).errorMessage,
        equals('Please enter an activity name.'));
    expect(fakeSessionRepo.saved, isNull);
  });

  test('ManualSessionController populates detected app usages', () async {
    final fakeSessionRepo = FakeSessionRepo();
    final fakePlanRepo = FakePlanBlockRepo();
    final fakeJournal = FakeActivityJournalRepo();

    final container = ProviderContainer(
      overrides: [
        sessionRepositoryProvider.overrideWithValue(fakeSessionRepo),
        planBlockRepositoryProvider.overrideWithValue(fakePlanRepo),
        activityJournalRepositoryProvider.overrideWithValue(fakeJournal),
      ],
    );
    addTearDown(container.dispose);

    final controller = container.read(manualSessionControllerProvider.notifier);
    await controller.refreshUsage();

    final usages = container.read(manualSessionControllerProvider).detectedAppUsages;
    expect(usages, isNotEmpty);
    expect(usages.first.appName, equals('VS Code'));

    controller.setRoutineName('Coding Session');
    final success = await controller.saveSession();
    expect(success, isTrue);
    expect(fakeSessionRepo.saved!.appUsages.length, equals(1));
    expect(fakeSessionRepo.saved!.appUsages.first.appName, equals('VS Code'));
  });
}
