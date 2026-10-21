import 'dart:convert';
import 'package:timer_engine/timer_engine.dart';

/// Turns a run's phase ledger into the payload of the `phase_ledger_json`
/// column and back.
///
/// The ledger's timestamps travel as ISO-8601 strings, so they keep their
/// millisecond precision; drift's own `dateTime` columns only store seconds.
class PhaseLedgerSerializer {
  const PhaseLedgerSerializer._();

  static String toJson(List<PhaseLedgerEntry> entries) {
    return jsonEncode({
      'schemaVersion': 1,
      'entries': entries
          .map((e) => {
                'phaseId': e.phaseId,
                'phaseName': e.phaseName,
                'kind': e.kind.name,
                'phaseIndex': e.phaseIndex,
                'repeatIndex': e.repeatIndex,
                'durationMs': e.durationMs,
                'outcome': e.outcome.name,
                'startedAtUtc': e.startedAtUtc.toIso8601String(),
                'endedAtUtc': e.endedAtUtc.toIso8601String(),
              })
          .toList(),
    });
  }

  /// Reads a ledger back. A payload that cannot be read yields an empty
  /// ledger instead of an error: a corrupt ledger must never keep a run
  /// from being recovered.
  static List<PhaseLedgerEntry> fromJson(String jsonString) {
    if (jsonString.trim().isEmpty) return const [];
    try {
      final decoded = jsonDecode(jsonString);
      if (decoded is! Map<String, dynamic>) return const [];
      final raw = decoded['entries'];
      if (raw is! List) return const [];
      return raw
          .map(_entryFromJson)
          .whereType<PhaseLedgerEntry>()
          .toList(growable: false);
    } catch (_) {
      return const [];
    }
  }

  /// Reads one entry defensively: a field that is missing or malformed
  /// falls back to a safe default, and an entry whose timestamps cannot be
  /// parsed is dropped rather than failing the whole ledger.
  static PhaseLedgerEntry? _entryFromJson(Object? raw) {
    if (raw is! Map<String, dynamic>) return null;

    final startedAt = _parseTimestamp(raw['startedAtUtc']);
    final endedAt = _parseTimestamp(raw['endedAtUtc']);
    if (startedAt == null || endedAt == null) return null;

    return PhaseLedgerEntry(
      phaseId: _asString(raw['phaseId']),
      phaseName: _asString(raw['phaseName']),
      kind: raw['kind'] == PhaseKind.rest.name ? PhaseKind.rest : PhaseKind.focus,
      phaseIndex: _asInt(raw['phaseIndex']),
      repeatIndex: _asInt(raw['repeatIndex']),
      durationMs: _asInt(raw['durationMs']),
      outcome: _parseOutcome(raw['outcome']),
      startedAtUtc: startedAt,
      endedAtUtc: endedAt,
    );
  }

  /// A phase that has ended is finished unless it says otherwise.
  static PhaseStatus _parseOutcome(Object? raw) {
    return PhaseStatus.values.firstWhere(
      (s) => s.name == raw,
      orElse: () => PhaseStatus.finished,
    );
  }

  static DateTime? _parseTimestamp(Object? raw) {
    if (raw is! String) return null;
    final parsed = DateTime.tryParse(raw);
    if (parsed == null) return null;
    return parsed.toUtc();
  }

  static String _asString(Object? raw) => raw is String ? raw : '';

  static int _asInt(Object? raw) => raw is num ? raw.toInt() : 0;
}
