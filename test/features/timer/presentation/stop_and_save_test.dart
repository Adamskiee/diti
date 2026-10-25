import 'package:flutter/material.dart' hide RepeatMode;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:diti/src/core/di/database_provider.dart';
import 'package:diti/src/core/di/notification_providers.dart';
import 'package:diti/src/core/di/repositories_provider.dart';
import 'package:diti/src/core/di/timer_engine_provider.dart';
import 'package:diti/src/core/navigation/app_shell.dart';
import 'package:diti/src/features/history/presentation/widgets/session_verification_sheet.dart';
import 'package:diti/src/features/routines/data/starter_routines.dart';
import 'package:diti/src/features/timer/controllers/active_timer_controller.dart';
import 'package:timer_engine/timer_engine.dart';
import '../../../../test/helpers/test_fakes.dart';

class TestNavObserver extends NavigatorObserver {
  final List<String> log = [];
  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    log.add('PUSH ${route.settings.name ?? route.runtimeType}');
  }
  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    log.add('POP ${route.settings.name ?? route.runtimeType}');
  }
}

void main() {
  testWidgets('Test Open Flow stop and save', (tester) async {
    final navObserver = TestNavObserver();
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final db = createInMemoryTestDatabase();
    final fakeClock = FakeClock(initialUtc: DateTime.utc(2026, 10, 16, 12, 0));
    final fakeClient = FakeNotificationClient();

    final container = ProviderContainer(
      overrides: [
        databaseProvider.overrideWithValue(db),
        monotonicClockProvider.overrideWithValue(fakeClock),
        wallClockProvider.overrideWithValue(fakeClock),
        notificationClientProvider.overrideWithValue(fakeClient),
      ],
    );

    final routineRepo = container.read(routineRepositoryProvider);
    await seedStarterRoutines(routineRepo);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          navigatorObservers: [navObserver],
          home: const AppShell(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Start Open Flow (third routine in list)
    final openFlowCard = find.text('Open Flow');
    expect(openFlowCard, findsOneWidget);
    final startButton = find.widgetWithText(FilledButton, 'Start').at(2);
    await tester.scrollUntilVisible(
      startButton,
      100,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(startButton);
    await tester.pumpAndSettle();

    // Advance 10 seconds
    fakeClock.advance(const Duration(seconds: 10));
    container.read(activeTimerControllerProvider.notifier).tick();
    await tester.pump();

    // Tap stop button
    await tester.tap(find.byKey(const Key('timer_stop_button')));
    await tester.pumpAndSettle();

    expect(find.byType(SessionVerificationSheet), findsOneWidget);

    // Tap Save to Analytics
    await tester.tap(find.text('Save to Analytics'));
    await tester.pumpAndSettle();

    // Verify sheet is dismissed and no second verification sheet appears
    expect(find.byType(SessionVerificationSheet), findsNothing);

    // Advance clock and pump to verify no delayed or second sheet triggers
    fakeClock.advance(const Duration(seconds: 5));
    await tester.pumpAndSettle();
    expect(find.byType(SessionVerificationSheet), findsNothing);

    // Verify session was persisted
    final allSessions = await db.select(db.sessions).get();
    expect(allSessions.length, 1);
    expect(allSessions.first.outcome, 'cancelled');

    container.dispose();
    await db.close();
  });
}
