import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:diti_notifications/diti_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'src/core/di/notification_providers.dart';
import 'src/core/di/repositories_provider.dart';
import 'src/core/navigation/app_shell.dart';
import 'src/core/theme/app_theme.dart';
import 'src/features/routines/data/starter_routines.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    const ProviderScope(
      child: DitiApp(),
    ),
  );
}

class DitiApp extends ConsumerStatefulWidget {
  const DitiApp({super.key});

  @override
  ConsumerState<DitiApp> createState() => _DitiAppState();
}

class _DitiAppState extends ConsumerState<DitiApp> {
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    tz.initializeTimeZones();
    await ref.read(notificationClientProvider).initialize(
          settings: LocalNotificationPort.defaultInitializationSettings,
        );

    final repo = ref.read(routineRepositoryProvider);
    await seedStarterRoutines(repo);

    if (mounted) {
      setState(() => _initialized = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_initialized) {
      return MaterialApp(
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        home: const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    return MaterialApp(
      title: 'Diti',
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      home: const AppShell(),
    );
  }
}
