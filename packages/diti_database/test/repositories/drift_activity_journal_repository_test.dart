import 'package:diti_database/diti_database.dart';
import 'package:drift/native.dart';
import 'package:test/test.dart';

void main() {
  late DitiDatabase db;
  late DriftActivityJournalRepository repo;

  setUp(() {
    db = DitiDatabase(NativeDatabase.memory());
    repo = DriftActivityJournalRepository(db);
  });

  tearDown(() async {
    await db.close();
  });

  test('records samples, aggregates usage by range, and prunes old samples',
      () async {
    final t1 = DateTime.utc(2026, 11, 1, 10, 0);
    final t2 = DateTime.utc(2026, 11, 1, 10, 2);
    final tOld = DateTime.utc(2026, 10, 31, 8, 0);

    // 1. Record samples
    await repo.recordSample(ActivitySampleRecord(
      id: 's1',
      sampledAtUtc: t1,
      durationMs: 3000,
      appName: 'VS Code',
      category: 'Development',
      sampleTitle: 'editor.dart',
    ));

    await repo.recordSample(ActivitySampleRecord(
      id: 's2',
      sampledAtUtc: t2,
      durationMs: 3000,
      appName: 'VS Code',
      category: 'Development',
      sampleTitle: 'main.dart',
    ));

    await repo.recordSample(ActivitySampleRecord(
      id: 's3',
      sampledAtUtc: t2,
      durationMs: 4000,
      appName: 'Firefox',
      category: 'Browser',
    ));

    await repo.recordSample(ActivitySampleRecord(
      id: 'sOld',
      sampledAtUtc: tOld,
      durationMs: 5000,
      appName: 'Slack',
      category: 'Communication',
    ));

    // 2. Aggregate within [t1, t2]
    final usages = await repo.aggregateUsageBetween(
      DateTime.utc(2026, 11, 1, 9, 59),
      DateTime.utc(2026, 11, 1, 10, 5),
    );

    expect(usages.length, equals(2));
    final vsCode = usages.firstWhere((u) => u.appName == 'VS Code');
    expect(vsCode.durationMs, equals(6000));
    expect(vsCode.category, equals('Development'));

    final firefox = usages.firstWhere((u) => u.appName == 'Firefox');
    expect(firefox.durationMs, equals(4000));

    // 3. Prune older than 24h cutoff
    final deleted = await repo.pruneOlderThan(DateTime.utc(2026, 11, 1, 0, 0));
    expect(deleted, equals(1));
  });
}
