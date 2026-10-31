import 'dart:async';
import 'dart:io';

import 'package:alchemist/alchemist.dart';

/// Global test configuration picked up automatically by `flutter test`.
///
/// CI goldens (text rendered as blocks) are OS-independent and always run.
/// Platform goldens (real fonts) are only generated locally for visual review
/// and are git-ignored.
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  final isRunningInCi = Platform.environment.containsKey('CI');

  return AlchemistConfig.runWithConfig(
    config: AlchemistConfig(
      ciGoldensConfig: const CiGoldensConfig(enabled: true),
      platformGoldensConfig: PlatformGoldensConfig(enabled: !isRunningInCi),
    ),
    run: testMain,
  );
}
