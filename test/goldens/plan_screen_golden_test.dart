// test/goldens/plan_screen_golden_test.dart
import 'dart:async';

import 'package:alchemist/alchemist.dart';
import 'package:diti/src/core/di/timer_engine_provider.dart';
import 'package:diti/src/core/theme/app_theme.dart';
import 'package:diti/src/features/plan/domain/daily_plan_state.dart';
import 'package:diti/src/features/plan/presentation/controllers/daily_plan_controller.dart';
import 'package:diti/src/features/plan/presentation/plan_screen.dart';
import 'package:diti/src/features/plan/providers/plan_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timer_engine/timer_engine.dart';

/// Returns a fixed, empty plan without touching the database so the golden
/// is fully deterministic.
class _EmptyPlanController extends DailyPlanController {
  @override
  FutureOr<DailyPlanState> build() => const DailyPlanState(
        dateString: '2026-10-16',
        blocks: [],
        conflicts: {},
        totalPlannedMs: 0,
        totalActualMs: 0,
      );
}

Widget _planScreen(ThemeData theme) {
  return SizedBox(
    width: 390,
    height: 844,
    child: ProviderScope(
      overrides: [
        wallClockProvider.overrideWithValue(
          FakeClock(initialUtc: DateTime.utc(2026, 10, 16, 10)),
        ),
        selectedDateProvider.overrideWith((ref) => DateTime(2026, 10, 16)),
        dailyPlanControllerProvider.overrideWith(_EmptyPlanController.new),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: theme,
        home: const PlanScreen(),
      ),
    ),
  );
}

void main() {
  goldenTest(
    'PlanScreen empty day renders in light and dark themes',
    fileName: 'plan_screen_empty',
    builder: () => GoldenTestGroup(
      children: [
        GoldenTestScenario(name: 'light', child: _planScreen(AppTheme.light)),
        GoldenTestScenario(name: 'dark', child: _planScreen(AppTheme.dark)),
      ],
    ),
  );
}
