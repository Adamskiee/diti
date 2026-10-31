import 'package:diti/main.dart';
import 'package:diti/src/core/di/database_provider.dart';
import 'package:diti/src/core/di/notification_providers.dart';
import 'package:diti/src/core/di/timer_engine_provider.dart';
import 'package:diti/src/core/navigation/app_shell.dart';
import 'package:diti/src/features/history/presentation/widgets/session_verification_sheet.dart';
import 'package:diti/src/features/timer/controllers/active_timer_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:timer_engine/timer_engine.dart';

import '../test/helpers/test_fakes.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('app boots, starts Classic Pomodoro, stops and saves session',
      (tester) async {
    final db = createInMemoryTestDatabase();
    final clock = FakeClock(initialUtc: DateTime.utc(2026, 10, 16, 10));
    // Fake notifications: CI Linux runners have no D-Bus notification daemon.
    // Native notification behaviour is covered by Patrol tests.
    final container = ProviderContainer(
      overrides: [
        databaseProvider.overrideWithValue(db),
        monotonicClockProvider.overrideWithValue(clock),
        wallClockProvider.overrideWithValue(clock),
        notificationClientProvider.overrideWithValue(FakeNotificationClient()),
      ],
    );
    addTearDown(() async {
      container.dispose();
      await db.close();
    });

    await tester.pumpWidget(
      UncontrolledProviderScope(container: container, child: const DitiApp()),
    );
    await tester.pumpAndSettle();

    expect(find.byType(AppShell), findsOneWidget);
    expect(find.text('Classic Pomodoro'), findsOneWidget);

    await tester.tap(find.text('Start').first);
    await tester.pumpAndSettle();
    expect(find.text('25:00'), findsOneWidget);
    expect(find.text('Focus'), findsOneWidget);

    clock.advance(const Duration(seconds: 5));
    container.read(activeTimerControllerProvider.notifier).tick();
    await tester.pump();

    await container.read(activeTimerControllerProvider.notifier).stop();
    await tester.pumpAndSettle();
    expect(find.byType(SessionVerificationSheet), findsOneWidget);

    await tester.tap(find.text('Save to Analytics'));
    await tester.pumpAndSettle();
    expect(find.byType(SessionVerificationSheet), findsNothing);
  });
}
