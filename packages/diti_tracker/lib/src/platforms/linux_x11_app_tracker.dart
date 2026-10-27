import 'dart:io';
import '../domain/active_app_sample.dart';
import '../ports/app_tracker_port.dart';
import '../ports/process_runner.dart';

class LinuxX11AppTracker implements AppTrackerPort {
  final ProcessRunner _runner;

  LinuxX11AppTracker({ProcessRunner processRunner = const SystemProcessRunner()})
      : _runner = processRunner;

  static final RegExp _windowIdRegex =
      RegExp(r'_NET_ACTIVE_WINDOW\([^)]*\)\s*[:=]\s*(?:window id #\s*)?(0x[0-9a-fA-F]+|\d+)');
  static final RegExp _wmClassLineRegex =
      RegExp(r'WM_CLASS\([^)]*\)\s*=\s*(.*)');
  static final RegExp _quotedStringRegex = RegExp(r'"([^"]*)"');
  static final RegExp _wmNameRegex =
      RegExp(r'_NET_WM_NAME\([^)]*\)\s*=\s*"([^"]*)"');

  static const String _kwinScriptPath = '/tmp/diti_kwin_probe.js';
  static bool _kwinScriptInitialized = false;

  @override
  Future<ActiveAppSample?> sampleActiveWindow() async {
    // 1. Try KWin on KDE Plasma (Wayland & X11)
    final kwinSample = await _sampleViaKWin();
    if (kwinSample != null) return kwinSample;

    // 2. Try X11 xprop
    final xpropSample = await _sampleViaXprop();
    if (xpropSample != null) return xpropSample;

    // 3. Fallback to xdotool
    return _sampleViaXdotool();
  }

  Future<ActiveAppSample?> _sampleViaKWin() async {
    try {
      if (!_kwinScriptInitialized) {
        final file = File(_kwinScriptPath);
        if (!file.existsSync()) {
          file.writeAsStringSync(
            'var w = workspace.activeClient || workspace.activeWindow;\n'
            'if (w) {\n'
            '    print("DITI_ACTIVE:" + (w.resourceClass || "") + ":::" + (w.caption || ""));\n'
            '}\n',
          );
        }
        _kwinScriptInitialized = true;
      }

      final loadResult = await _runner.run('busctl', [
        '--user',
        'call',
        'org.kde.KWin',
        '/Scripting',
        'org.kde.kwin.Scripting',
        'loadScript',
        's',
        _kwinScriptPath,
      ]);
      if (loadResult.exitCode != 0) return null;

      final loadOut = loadResult.stdout.toString().trim();
      final parts = loadOut.split(RegExp(r'\s+'));
      if (parts.isEmpty) return null;
      final scriptNum = parts.last;
      if (int.tryParse(scriptNum) == null) return null;

      // Run script to trigger log print
      await _runner.run('busctl', [
        '--user',
        'call',
        'org.kde.KWin',
        '/$scriptNum',
        'org.kde.kwin.Script',
        'run',
      ]);

      // Stop script
      await _runner.run('busctl', [
        '--user',
        'call',
        'org.kde.KWin',
        '/$scriptNum',
        'org.kde.kwin.Script',
        'stop',
      ]);

      // Unload script
      await _runner.run('busctl', [
        '--user',
        'call',
        'org.kde.KWin',
        '/Scripting',
        'org.kde.kwin.Scripting',
        'unloadScript',
        's',
        _kwinScriptPath,
      ]);

      // Read active window from journal
      final journalResult = await _runner.run('journalctl', [
        '_COMM=kwin_wayland',
        '-n',
        '5',
        '-o',
        'cat',
      ]);
      if (journalResult.exitCode != 0) return null;

      final lines = journalResult.stdout.toString().split('\n');
      for (final line in lines.reversed) {
        if (line.contains('DITI_ACTIVE:')) {
          final payload = line.split('DITI_ACTIVE:').last.trim();
          final split = payload.split(':::');
          final rawClass = split.first.trim();
          final rawTitle =
              split.length > 1 ? split.sublist(1).join(':::').trim() : '';
          if (rawClass.isNotEmpty || rawTitle.isNotEmpty) {
            return ActiveAppSample(
              rawClass: rawClass,
              rawTitle: rawTitle,
              sampledAt: DateTime.now().toUtc(),
            );
          }
        }
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  Future<ActiveAppSample?> _sampleViaXprop() async {
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
      final classLine = _wmClassLineRegex.firstMatch(detailsOut)?.group(1) ?? '';
      final classMatches = _quotedStringRegex
          .allMatches(classLine)
          .map((m) => m.group(1))
          .whereType<String>()
          .toList();
      final nameMatch = _wmNameRegex.firstMatch(detailsOut);

      final rawClass = classMatches.join(' ');
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

  Future<ActiveAppSample?> _sampleViaXdotool() async {
    try {
      final classResult = await _runner.run('xdotool', [
        'getactivewindow',
        'getwindowclassname',
      ]);
      final titleResult = await _runner.run('xdotool', [
        'getactivewindow',
        'getwindowname',
      ]);

      if (classResult.exitCode == 0 || titleResult.exitCode == 0) {
        final rawClass = classResult.exitCode == 0
            ? classResult.stdout.toString().trim()
            : '';
        final rawTitle = titleResult.exitCode == 0
            ? titleResult.stdout.toString().trim()
            : '';

        if (rawClass.isNotEmpty || rawTitle.isNotEmpty) {
          return ActiveAppSample(
            rawClass: rawClass,
            rawTitle: rawTitle,
            sampledAt: DateTime.now().toUtc(),
          );
        }
      }
      return null;
    } catch (_) {
      return null;
    }
  }
}
