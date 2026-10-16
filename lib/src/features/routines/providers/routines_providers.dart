import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timer_engine/timer_engine.dart';
import '../presentation/controllers/routine_list_controller.dart';

final routineListControllerProvider =
    AsyncNotifierProvider<RoutineListController, List<Routine>>(
  RoutineListController.new,
);
