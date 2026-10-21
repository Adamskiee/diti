import 'package:test/test.dart';
import 'package:timer_engine/src/domain/command_result.dart';
import 'package:timer_engine/src/domain/enums.dart';

void main() {
  group('Enums & CommandResult', () {
    test('TimerCommandResult holds success and stateVersion', () {
      const successResult = TimerCommandResult(
        success: true,
        stateVersion: 1,
      );
      expect(successResult.success, isTrue);
      expect(successResult.error, isNull);
      expect(successResult.stateVersion, equals(1));

      const errorResult = TimerCommandResult(
        success: false,
        error: TimerError.invalidTransition,
        stateVersion: 2,
      );
      expect(errorResult.success, isFalse);
      expect(errorResult.error, equals(TimerError.invalidTransition));
      expect(errorResult.stateVersion, equals(2));
    });

    test('TimerCommandResult equality and hashCode', () {
      const a = TimerCommandResult(success: true, stateVersion: 1);
      const b = TimerCommandResult(success: true, stateVersion: 1);
      const c = TimerCommandResult(
        success: false,
        error: TimerError.invalidTransition,
        stateVersion: 1,
      );
      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
      expect(a, isNot(equals(c)));
      expect(
        a.toString(),
        equals('TimerCommandResult(success: true, error: null, stateVersion: 1)'),
      );
    });

    test('Enums have expected values', () {
      expect(RunStatus.values, [
        RunStatus.idle,
        RunStatus.running,
        RunStatus.paused,
        RunStatus.completed,
        RunStatus.cancelled,
      ]);
      expect(PhaseStatus.values, [
        PhaseStatus.active,
        PhaseStatus.awaitingAction,
        PhaseStatus.finished,
        PhaseStatus.skipped,
      ]);
      expect(TransitionPolicy.values, [
        TransitionPolicy.auto,
        TransitionPolicy.manual,
      ]);
      expect(RepeatMode.values, [
        RepeatMode.count,
        RepeatMode.forever,
      ]);
      expect(TimerError.values, [
        TimerError.invalidConfiguration,
        TimerError.invalidTransition,
        TimerError.runNotFound,
        TimerError.staleState,
        TimerError.persistenceFailure,
      ]);
      expect(PhaseKind.values, [
        PhaseKind.focus,
        PhaseKind.rest,
      ]);
    });
  });
}
