import 'package:diti/main.dart';
import 'package:diti/src/core/di/database_provider.dart';
import 'package:diti/src/core/di/notification_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:patrol/patrol.dart';

import '../test/helpers/test_fakes.dart';

void main() {
  patrolTest(
    'granting the native POST_NOTIFICATIONS dialog enables notifications',
    ($) async {
      final db = createInMemoryTestDatabase();
      final container = ProviderContainer(
        overrides: [databaseProvider.overrideWithValue(db)],
      );
      addTearDown(() async {
        container.dispose();
        await db.close();
      });

      await $.pumpWidgetAndSettle(
        UncontrolledProviderScope(container: container, child: const DitiApp()),
      );

      // The app has no UI that triggers the prompt, so request it directly.
      final granted = container
          .read(notificationPermissionServiceProvider)
          .requestNotificationPermissions();

      if (await $.platform.mobile.isPermissionDialogVisible(
        timeout: const Duration(seconds: 10),
      )) {
        await $.platform.mobile.grantPermissionWhenInUse();
      }

      expect(await granted, isTrue);

      await $('Settings').tap();
      await $.pumpAndSettle();
      expect($('Enabled'), findsOneWidget);
    },
  );
}
