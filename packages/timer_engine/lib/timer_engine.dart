/// Pure Dart Timer Engine.
///
/// Provides a zero-dependency, deterministic timer state machine, clock abstractions,
/// domain entities, ports, and crash recovery.
library timer_engine;

export 'src/clock/cancelable_token.dart';
export 'src/clock/monotonic_clock.dart';
export 'src/clock/wall_clock.dart';
export 'src/clock/system_clock.dart';

export 'src/domain/enums.dart';
export 'src/domain/repeat_rule.dart';
export 'src/domain/routine_phase.dart';
export 'src/domain/routine.dart';
export 'src/domain/timer_run.dart';
export 'src/domain/timer_run_state.dart';
export 'src/domain/timer_event.dart';
export 'src/domain/command_result.dart';

export 'src/ports/routine_repository.dart';
export 'src/ports/run_persistence_port.dart';
export 'src/ports/notification_port.dart';

export 'src/engine/timer_engine.dart';
export 'src/engine/timer_engine_impl.dart';
export 'src/engine/recovery_manager.dart';
