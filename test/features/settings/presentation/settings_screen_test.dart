import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:diti/src/core/di/app_info_providers.dart';
import 'package:diti/src/core/di/database_provider.dart';
import 'package:diti/src/core/di/notification_providers.dart';
import 'package:diti/src/core/di/tracker_provider.dart';
import 'package:diti/src/features/settings/presentation/controllers/settings_controller.dart';
import 'package:diti/src/features/settings/presentation/settings_screen.dart';
import '../../../helpers/test_fakes.dart';

void main() {
  group('SettingsScreen', () {
    testWidgets('renders dynamic version from packageInfoProvider',
        (tester) async {
      final fakePermission = FakePermissionService();

      final container = ProviderContainer(
        overrides: [
          notificationPermissionServiceProvider
              .overrideWithValue(fakePermission),
          packageInfoProvider.overrideWith(
            (ref) => PackageInfo(
              appName: 'Diti',
              packageName: 'com.adilabs.diti',
              version: '2.2.0',
              buildNumber: '',
              buildSignature: '',
            ),
          ),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: SettingsScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Version'), findsOneWidget);
      expect(find.text('2.2.0'), findsOneWidget);
      expect(find.text('0.1.0 (Phase 4A)'), findsNothing);
    });

    testWidgets('renders version with build number when present',
        (tester) async {
      final fakePermission = FakePermissionService();

      final container = ProviderContainer(
        overrides: [
          notificationPermissionServiceProvider
              .overrideWithValue(fakePermission),
          packageInfoProvider.overrideWith(
            (ref) => PackageInfo(
              appName: 'Diti',
              packageName: 'com.adilabs.diti',
              version: '2.2.0',
              buildNumber: '42',
              buildSignature: '',
            ),
          ),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: SettingsScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('2.2.0+42'), findsOneWidget);
    });

    testWidgets('renders Loading... while version is loading', (tester) async {
      final fakePermission = FakePermissionService();
      final completer = Completer<PackageInfo>();

      final container = ProviderContainer(
        overrides: [
          notificationPermissionServiceProvider
              .overrideWithValue(fakePermission),
          packageInfoProvider.overrideWith((ref) => completer.future),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: SettingsScreen(),
          ),
        ),
      );

      await tester.pump(); // don't settle yet, future is unresolved

      expect(find.text('Loading...'), findsOneWidget);

      completer.complete(
        PackageInfo(
          appName: 'Diti',
          packageName: 'com.adilabs.diti',
          version: '2.2.0',
          buildNumber: '',
          buildSignature: '',
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Loading...'), findsNothing);
      expect(find.text('2.2.0'), findsOneWidget);
    });

    testWidgets('renders Unknown when appVersionProvider throws error',
        (tester) async {
      final fakePermission = FakePermissionService();

      final container = ProviderContainer(
        overrides: [
          notificationPermissionServiceProvider
              .overrideWithValue(fakePermission),
          appVersionProvider
              .overrideWith((ref) => Future.error('Failed to load version')),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: SettingsScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Unknown'), findsOneWidget);
    });

    testWidgets('renders continuous tracking switch and toggles it',
        (tester) async {
      final fakePermission = FakePermissionService();
      final db = createInMemoryTestDatabase();

      final container = ProviderContainer(
        overrides: [
          databaseProvider.overrideWithValue(db),
          notificationPermissionServiceProvider
              .overrideWithValue(fakePermission),
          packageInfoProvider.overrideWith(
            (ref) => PackageInfo(
              appName: 'Diti',
              packageName: 'com.adilabs.diti',
              version: '2.2.0',
              buildNumber: '',
              buildSignature: '',
            ),
          ),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: SettingsScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Activity Tracking'), findsOneWidget);
      expect(find.text('Continuous Background Tracking'), findsOneWidget);
      expect(
        find.text(
          'Track active window history (rolling 24 hours) to include app usage when recovering untimed sessions.',
        ),
        findsOneWidget,
      );

      final switchTileFinder = find.byType(SwitchListTile);
      expect(switchTileFinder, findsOneWidget);
      expect(container.read(continuousTrackingEnabledProvider), isTrue);

      // Tap the switch to toggle it to false
      await tester.tap(switchTileFinder);
      await tester.pumpAndSettle();

      expect(container.read(continuousTrackingEnabledProvider), isFalse);

      // Tap again to toggle it back to true
      await tester.tap(switchTileFinder);
      await tester.pumpAndSettle();

      expect(container.read(continuousTrackingEnabledProvider), isTrue);

      container.read(continuousActivityTrackerProvider).stop();
    });
  });
}
