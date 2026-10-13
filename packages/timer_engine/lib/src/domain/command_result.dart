import 'enums.dart';

class TimerCommandResult {
  final bool success;
  final TimerError? error;
  final int stateVersion;

  const TimerCommandResult({
    required this.success,
    this.error,
    required this.stateVersion,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TimerCommandResult &&
          runtimeType == other.runtimeType &&
          success == other.success &&
          error == other.error &&
          stateVersion == other.stateVersion;

  @override
  int get hashCode => Object.hash(success, error, stateVersion);

  @override
  String toString() =>
      'TimerCommandResult(success: $success, error: $error, stateVersion: $stateVersion)';
}
