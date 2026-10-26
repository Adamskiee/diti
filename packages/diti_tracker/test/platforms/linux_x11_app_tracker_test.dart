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
      expect(sample!.rawClass, equals('google-chrome'));
      expect(sample.rawTitle, equals('The Beatles - Let It Be - YouTube - Google Chrome'));
    });

    test('returns null when active window id is not found or desktop is idle', () async {
      final fakeRunner = FakeProcessRunner({
        'xprop -root _NET_ACTIVE_WINDOW': ProcessResult(
          0,
          0,
          '_NET_ACTIVE_WINDOW(WINDOW): window id # 0x0\n',
          '',
        ),
      });

      final tracker = LinuxX11AppTracker(processRunner: fakeRunner);
      final sample = await tracker.sampleActiveWindow();

      expect(sample, isNull);
    });

    test('returns null gracefully on xprop process failure', () async {
      final fakeRunner = FakeProcessRunner({
        'xprop -root _NET_ACTIVE_WINDOW': ProcessResult(
          0,
          1,
          '',
          'xprop: unable to open display\n',
        ),
      });

      final tracker = LinuxX11AppTracker(processRunner: fakeRunner);
      final sample = await tracker.sampleActiveWindow();

      expect(sample, isNull);
    });
  });
}
