import 'enums.dart';

class RepeatRule {
  final RepeatMode mode;
  final int count;

  const RepeatRule({
    required this.mode,
    this.count = 1,
  });

  bool get isValid => mode == RepeatMode.forever || count >= 1;

  RepeatRule copyWith({
    RepeatMode? mode,
    int? count,
  }) {
    return RepeatRule(
      mode: mode ?? this.mode,
      count: count ?? this.count,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RepeatRule &&
          runtimeType == other.runtimeType &&
          mode == other.mode &&
          count == other.count;

  @override
  int get hashCode => Object.hash(mode, count);
}
