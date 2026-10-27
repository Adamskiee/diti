import 'dart:io';
import 'package:test/test.dart';
import 'package:diti_tracker/diti_tracker.dart';

class FakeProcessRunner implements ProcessRunner {
  final Map<String, ProcessResult> responses;
  FakeProcessRunner(this.responses);

  @override
  Future<ProcessResult> run(
    String executable,
    List<String> arguments, {
    bool runInShell = false,
  }) async {
    final key = '$executable ${arguments.join(' ')}';
    if (responses.containsKey(key)) {
      return responses[key]!;
    }
    return ProcessResult(0, 1, '', 'Command not mocked: $key');
  }
}

void main() {
  group('LinuxX11AppTracker', () {
    test('extracts WM_CLASS and window title correctly from xprop output', () async {
      final fakeRunner = FakeProcessRunner({
        'xprop -root _NET_ACTIVE_WINDOW': ProcessResult(
          0,
          0,
          '_NET_ACTIVE_WINDOW(WINDOW): window id # 0x4800007\n',
          '',
        ),
        'xprop -id 0x4800007 WM_CLASS _NET_WM_NAME': ProcessResult(
          0,
          0,
          'WM_CLASS(STRING) = "google-chrome", "Google-chrome"\n'
          '_NET_WM_NAME(UTF8_STRING) = "The Beatles - Let It Be - YouTube - Google Chrome"\n',
          '',
        ),
      });

      final tracker = LinuxX11AppTracker(processRunner: fakeRunner);
      final sample = await tracker.sampleActiveWindow();

      expect(sample, isNotNull);
      expect(sample!.rawClass, equals('google-chrome Google-chrome'));
      expect(sample.rawTitle, equals('The Beatles - Let It Be - YouTube - Google Chrome'));
    });

    test('extracts multi-string WM_CLASS such as Navigator firefox', () async {
      final fakeRunner = FakeProcessRunner({
        'xprop -root _NET_ACTIVE_WINDOW': ProcessResult(
          0,
          0,
          '_NET_ACTIVE_WINDOW(WINDOW): window id # 0x5a00001\n',
          '',
        ),
        'xprop -id 0x5a00001 WM_CLASS _NET_WM_NAME': ProcessResult(
          0,
          0,
          'WM_CLASS(STRING) = "Navigator", "firefox"\n'
          '_NET_WM_NAME(UTF8_STRING) = "Mozilla Firefox"\n',
          '',
        ),
      });

      final tracker = LinuxX11AppTracker(processRunner: fakeRunner);
      final sample = await tracker.sampleActiveWindow();

      expect(sample, isNotNull);
      expect(sample!.rawClass, equals('Navigator firefox'));
      expect(sample.rawTitle, equals('Mozilla Firefox'));
    });

    test('falls back to xdotool when xprop returns 0x0', () async {
      final fakeRunner = FakeProcessRunner({
        'xprop -root _NET_ACTIVE_WINDOW': ProcessResult(
          0,
          0,
          '_NET_ACTIVE_WINDOW(WINDOW): window id # 0x0\n',
          '',
        ),
        'xdotool getactivewindow getwindowclassname': ProcessResult(
          0,
          0,
          'alacritty\n',
          '',
        ),
        'xdotool getactivewindow getwindowname': ProcessResult(
          0,
          0,
          'bash - /home/user\n',
          '',
        ),
      });

      final tracker = LinuxX11AppTracker(processRunner: fakeRunner);
      final sample = await tracker.sampleActiveWindow();

      expect(sample, isNotNull);
      expect(sample!.rawClass, equals('alacritty'));
      expect(sample.rawTitle, equals('bash - /home/user'));
    });

    test('extracts active window via KWin DBus on KDE Wayland', () async {
      final fakeRunner = FakeProcessRunner({
        'busctl --user call org.kde.KWin /Scripting org.kde.kwin.Scripting loadScript s /tmp/diti_kwin_probe.js':
            ProcessResult(0, 0, 'int32 42\n', ''),
        'busctl --user call org.kde.KWin /42 org.kde.kwin.Script run':
            ProcessResult(0, 0, '', ''),
        'busctl --user call org.kde.KWin /42 org.kde.kwin.Script stop':
            ProcessResult(0, 0, '', ''),
        'busctl --user call org.kde.KWin /Scripting org.kde.kwin.Scripting unloadScript s /tmp/diti_kwin_probe.js':
            ProcessResult(0, 0, '', ''),
        'journalctl _COMM=kwin_wayland -n 5 -o cat': ProcessResult(
          0,
          0,
          'js: DITI_ACTIVE:brave-browser:::(1) YouTube - Brave\n',
          '',
        ),
      });

      final tracker = LinuxX11AppTracker(processRunner: fakeRunner);
      final sample = await tracker.sampleActiveWindow();

      expect(sample, isNotNull);
      expect(sample!.rawClass, equals('brave-browser'));
      expect(sample.rawTitle, equals('(1) YouTube - Brave'));
    });

    test('returns null when both xprop and xdotool fail', () async {
      final fakeRunner = FakeProcessRunner({
        'xprop -root _NET_ACTIVE_WINDOW': ProcessResult(
          0,
          1,
          '',
          'xprop: unable to open display\n',
        ),
        'xdotool getactivewindow getwindowclassname': ProcessResult(
          0,
          1,
          '',
          'There are no windows in the stack\n',
        ),
        'xdotool getactivewindow getwindowname': ProcessResult(
          0,
          1,
          '',
          'There are no windows in the stack\n',
        ),
      });

      final tracker = LinuxX11AppTracker(processRunner: fakeRunner);
      final sample = await tracker.sampleActiveWindow();

      expect(sample, isNull);
    });
  });
}
