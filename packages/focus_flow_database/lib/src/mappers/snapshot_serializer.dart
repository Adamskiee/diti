import 'dart:convert';
import 'package:timer_engine/timer_engine.dart';

class SnapshotSerializer {
  const SnapshotSerializer._();

  static String routineToJson(Routine routine) {
    final map = {
      'schemaVersion': 1,
      'id': routine.id,
      'name': routine.name,
      'repeatRule': {
        'mode': routine.repeatRule.mode.name,
        'count': routine.repeatRule.count,
      },
      'phases': routine.phases
          .map((p) => {
                'id': p.id,
                'name': p.name,
                'durationMs': p.durationMs,
                'transition': p.transition.name,
              })
          .toList(),
    };
    return jsonEncode(map);
  }

  static Routine routineFromJson(String jsonString) {
    final dynamic decoded = jsonDecode(jsonString);
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('Expected JSON map for routine snapshot');
    }

    final id = decoded['id'] as String? ?? '';
    final name = decoded['name'] as String? ?? '';

    final repeatMap = decoded['repeatRule'] as Map<String, dynamic>? ?? {};
    final repeatModeStr = repeatMap['mode'] as String? ?? 'count';
    final repeatMode = repeatModeStr == 'forever' ? RepeatMode.forever : RepeatMode.count;
    final repeatCount = (repeatMap['count'] as num?)?.toInt() ?? 1;

    final phasesRaw = decoded['phases'] as List<dynamic>? ?? [];
    final phases = phasesRaw.map((item) {
      final pMap = item as Map<String, dynamic>;
      final pId = pMap['id'] as String? ?? '';
      final pName = pMap['name'] as String? ?? '';
      final pDuration = (pMap['durationMs'] as num?)?.toInt();
      final pTransStr = pMap['transition'] as String? ?? 'auto';
      final pTrans = pTransStr == 'manual' ? TransitionPolicy.manual : TransitionPolicy.auto;

      return RoutinePhase(
        id: pId,
        name: pName,
        durationMs: pDuration,
        transition: pTrans,
      );
    }).toList(growable: false);

    return Routine(
      id: id,
      name: name,
      repeatRule: RepeatRule(mode: repeatMode, count: repeatCount),
      phases: phases,
    );
  }

  static String metadataToJson(Map<String, dynamic> metadata) {
    return jsonEncode(metadata);
  }

  static Map<String, dynamic> metadataFromJson(String jsonString) {
    if (jsonString.trim().isEmpty) return <String, dynamic>{};
    final dynamic decoded = jsonDecode(jsonString);
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('Expected JSON map for metadata');
    }
    return decoded;
  }
}
