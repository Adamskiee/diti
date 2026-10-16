import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'src/core/di/repositories_provider.dart';
import 'src/core/navigation/app_shell.dart';
import 'src/core/theme/app_theme.dart';
import 'src/features/routines/data/starter_routines.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    const ProviderScope(
      child: FocusFlowApp(),
    ),
  );
}

class FocusFlowApp extends ConsumerStatefulWidget {
  const FocusFlowApp({super.key});

  @override
  ConsumerState<FocusFlowApp> createState() => _FocusFlowAppState();
}

class _FocusFlowAppState extends ConsumerState<FocusFlowApp> {
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
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
      title: 'FocusFlow',
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      home: const AppShell(),
    );
  }
}
