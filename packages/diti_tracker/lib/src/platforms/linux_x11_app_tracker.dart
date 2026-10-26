import '../domain/active_app_sample.dart';
import '../ports/app_tracker_port.dart';
import '../ports/process_runner.dart';

class LinuxX11AppTracker implements AppTrackerPort {
  final ProcessRunner _runner;

  LinuxX11AppTracker({ProcessRunner processRunner = const SystemProcessRunner()})
      : _runner = processRunner;

  static final RegExp _windowIdRegex =
      RegExp(r'_NET_ACTIVE_WINDOW\([^)]*\)\s*[:=]\s*(?:window id #\s*)?(0x[0-9a-fA-F]+|\d+)');
  static final RegExp _wmClassRegex =
      RegExp(r'WM_CLASS\([^)]*\)\s*=\s*"([^"]*)"');
  static final RegExp _wmNameRegex =
      RegExp(r'_NET_WM_NAME\([^)]*\)\s*=\s*"([^"]*)"');

  @override
  Future<ActiveAppSample?> sampleActiveWindow() async {
    try {
      final activeWindowResult = await _runner.run('xprop', [
        '-root',
        '_NET_ACTIVE_WINDOW',
      ]);
      if (activeWindowResult.exitCode != 0) {
        return null;
      }

      final windowOut = activeWindowResult.stdout.toString();
      final match = _windowIdRegex.firstMatch(windowOut);
      if (match == null) return null;

      final windowId = match.group(1);
      if (windowId == null || windowId == '0x0' || windowId == '0') {
        return null;
      }

      final detailsResult = await _runner.run('xprop', [
        '-id',
        windowId,
        'WM_CLASS',
        '_NET_WM_NAME',
      ]);
      if (detailsResult.exitCode != 0) {
        return null;
      }

      final detailsOut = detailsResult.stdout.toString();
      final classMatch = _wmClassRegex.firstMatch(detailsOut);
      final nameMatch = _wmNameRegex.firstMatch(detailsOut);

      final rawClass = classMatch?.group(1) ?? '';
      final rawTitle = nameMatch?.group(1) ?? '';

      if (rawClass.isEmpty && rawTitle.isEmpty) {
        return null;
      }

      return ActiveAppSample(
        rawClass: rawClass,
        rawTitle: rawTitle,
        sampledAt: DateTime.now().toUtc(),
      );
    } catch (_) {
      return null;
    }
  }
}
