/// Drift SQLite persistence layer and adapters for Diti.
library diti_database;

// Database & tables
export 'src/database/diti_database.dart'
    hide Routine, RoutinePhase, TimerRun, TimerEvent, PlanBlock;
export 'src/database/tables/routines_table.dart';
export 'src/database/tables/routine_phases_table.dart';
export 'src/database/tables/timer_runs_table.dart';
export 'src/database/tables/timer_events_table.dart';
export 'src/database/tables/sessions_table.dart';
export 'src/database/tables/session_events_table.dart';
export 'src/database/tables/plan_blocks_table.dart';

// DAOs
export 'src/daos/routines_dao.dart';
export 'src/daos/timer_runs_dao.dart';
export 'src/daos/sessions_dao.dart';
export 'src/daos/plan_blocks_dao.dart';

// Domain models
export 'src/domain/session_record.dart';
export 'src/domain/plan_block.dart';

// Mappers & Serializers
export 'src/mappers/snapshot_serializer.dart';

// Repositories & Adapters
export 'src/repositories/drift_routine_repository.dart';
export 'src/repositories/drift_run_persistence_port.dart';
export 'src/repositories/session_repository.dart';
export 'src/repositories/drift_session_repository.dart';
export 'src/repositories/plan_block_repository.dart';
export 'src/repositories/drift_plan_block_repository.dart';
