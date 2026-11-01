import 'package:diti/main.dart';
import 'package:diti/src/core/di/database_provider.dart';
import 'package:diti/src/core/di/notification_providers.dart';
import 'package:flutter/material.dart';
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

      await $('Settings & Diagnostics').waitUntilVisible();

      // Allow the platform channel check to resolve across the async event loop:
      await Future<void>.delayed(const Duration(seconds: 1));
      await $.pumpAndSettle();

      // If the permission check resolved after the initial build, trigger refresh
      if ($('Enabled').evaluate().isEmpty) {
        await $(Icons.refresh).tap();
        await $.pumpAndSettle();
      }

      await $('Enabled').waitUntilVisible(timeout: const Duration(seconds: 10));
      expect($('Enabled'), findsOneWidget);
    },
  );
}
