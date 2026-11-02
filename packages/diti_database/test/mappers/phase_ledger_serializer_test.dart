import 'dart:convert';
import 'package:test/test.dart';
import 'package:timer_engine/timer_engine.dart';
import 'package:diti_database/diti_database.dart';

void main() {
  group('PhaseLedgerSerializer', () {
    test('round-trips a ledger', () {
      final entries = [
        PhaseLedgerEntry(
          phaseId: 'f',
          phaseName: 'Focus',
          kind: PhaseKind.focus,
          phaseIndex: 0,
          repeatIndex: 1,
          durationMs: 1500000,
          outcome: PhaseStatus.finished,
          startedAtUtc: DateTime.utc(2026, 10, 21, 9, 0),
          endedAtUtc: DateTime.utc(2026, 10, 21, 9, 25),
        ),
      ];
      final restored =
          PhaseLedgerSerializer.fromJson(PhaseLedgerSerializer.toJson(entries));
      expect(restored.length, 1);
      expect(restored.first.phaseId, 'f');
      expect(restored.first.kind, PhaseKind.focus);
      expect(restored.first.repeatIndex, 1);
      expect(restored.first.durationMs, 1500000);
      expect(restored.first.endedAtUtc, DateTime.utc(2026, 10, 21, 9, 25));
    });

    test('returns an empty list for malformed json', () {
      expect(PhaseLedgerSerializer.fromJson('not json'), isEmpty);
      expect(
          PhaseLedgerSerializer.fromJson(
              '{"schemaVersion":1,"entries":"nope"}'),
          isEmpty);
    });

    test('returns an empty list for an empty string', () {
      expect(PhaseLedgerSerializer.fromJson(''), isEmpty);
    });

    test('reads the column default and a payload without entries as empty', () {
      // '[]' is the default of the phase_ledger_json column, so a run that
      // was written before the ledger existed must read back as empty.
      expect(PhaseLedgerSerializer.fromJson('[]'), isEmpty);
      expect(PhaseLedgerSerializer.fromJson('{"schemaVersion":1}'), isEmpty);
    });

    test('writes schemaVersion 1 and one entry per phase', () {
      final json = jsonDecode(PhaseLedgerSerializer.toJson(const []))
          as Map<String, dynamic>;
      expect(json['schemaVersion'], 1);
      expect(json['entries'], isEmpty);
    });

    test('keeps every field of an entry', () {
      final entries = [
        PhaseLedgerEntry(
          phaseId: 'b',
          phaseName: 'Short Break',
          kind: PhaseKind.rest,
          phaseIndex: 1,
          repeatIndex: 0,
          durationMs: 300000,
          outcome: PhaseStatus.skipped,
          startedAtUtc: DateTime.utc(2026, 10, 21, 9, 25),
          endedAtUtc: DateTime.utc(2026, 10, 21, 9, 30),
        ),
      ];

      final restored =
          PhaseLedgerSerializer.fromJson(PhaseLedgerSerializer.toJson(entries));

      expect(restored.length, 1);
      expect(restored.first, equals(entries.first));
      expect(restored.first.phaseName, 'Short Break');
      expect(restored.first.kind, PhaseKind.rest);
      expect(restored.first.phaseIndex, 1);
      expect(restored.first.outcome, PhaseStatus.skipped);
      expect(restored.first.startedAtUtc, DateTime.utc(2026, 10, 21, 9, 25));
    });

    test('keeps millisecond precision in the timestamps', () {
      final entries = [
        PhaseLedgerEntry(
          phaseId: 'f',
          phaseName: 'Focus',
          kind: PhaseKind.focus,
          phaseIndex: 0,
          repeatIndex: 0,
          durationMs: 1234,
          outcome: PhaseStatus.finished,
          startedAtUtc: DateTime.utc(2026, 10, 21, 9, 0, 0, 123),
          endedAtUtc: DateTime.utc(2026, 10, 21, 9, 0, 1, 456),
        ),
      ];

      final restored =
          PhaseLedgerSerializer.fromJson(PhaseLedgerSerializer.toJson(entries));

      expect(restored.first.startedAtUtc,
          DateTime.utc(2026, 10, 21, 9, 0, 0, 123));
      expect(
          restored.first.endedAtUtc, DateTime.utc(2026, 10, 21, 9, 0, 1, 456));
    });

    test('defaults a missing kind to focus and a missing duration to zero', () {
      const json = '{"schemaVersion":1,"entries":[{"phaseId":"p",'
          '"phaseName":"Focus","phaseIndex":0,"repeatIndex":0,'
          '"outcome":"finished","startedAtUtc":"2026-10-21T09:00:00.000Z",'
          '"endedAtUtc":"2026-10-21T09:25:00.000Z"}]}';

      final restored = PhaseLedgerSerializer.fromJson(json);

      expect(restored.length, 1);
      expect(restored.first.kind, PhaseKind.focus);
      expect(restored.first.durationMs, 0);
    });

    test('drops an entry whose timestamps cannot be parsed', () {
      const json = '{"schemaVersion":1,"entries":['
          '{"phaseId":"p","phaseName":"Focus","durationMs":1000,'
          '"startedAtUtc":"not a date","endedAtUtc":"2026-10-21T09:25:00.000Z"}]}';

      expect(PhaseLedgerSerializer.fromJson(json), isEmpty);
    });

    test('keeps the readable entries when one of them is broken', () {
      const json = '{"schemaVersion":1,"entries":['
          '{"phaseId":"broken","durationMs":1000,'
          '"startedAtUtc":"not a date","endedAtUtc":"2026-10-21T09:25:00.000Z"},'
          '{"phaseId":"good","phaseName":"Focus","kind":"focus","durationMs":1000,'
          '"phaseIndex":0,"repeatIndex":0,"outcome":"finished",'
          '"startedAtUtc":"2026-10-21T09:00:00.000Z",'
          '"endedAtUtc":"2026-10-21T09:25:00.000Z"}]}';

      final restored = PhaseLedgerSerializer.fromJson(json);

      expect(restored.length, 1);
      expect(restored.first.phaseId, 'good');
    });
  });
}
