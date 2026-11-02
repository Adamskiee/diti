import 'package:test/test.dart';
import 'package:diti_tracker/diti_tracker.dart';

void main() {
  group('AppIdentityRules', () {
    test('identifies terminal emulators by WM_CLASS', () {
      final terminals = [
        'alacritty',
        'kitty',
        'gnome-terminal',
        'konsole',
        'xterm',
        'foot'
      ];
      for (final term in terminals) {
        final result = AppIdentityRules.identify(term, 'user@host: ~/dev');
        expect(result.appName, equals('Terminal'));
        expect(result.category, equals('Terminal'));
      }
    });

    test('identifies YouTube when running inside browser with YouTube in title',
        () {
      final browsers = {
        'google-chrome': 'Google Chrome',
        'chromium': 'Chromium',
        'firefox': 'Firefox',
        'brave-browser': 'Brave',
        'microsoft-edge': 'Edge',
      };
      for (final entry in browsers.entries) {
        final result = AppIdentityRules.identify(
            entry.key, 'Flutter State Management - YouTube - ${entry.value}');
        expect(result.appName, equals(entry.value));
        expect(result.category, equals('YouTube'));
        expect(result.sampleTitle, equals('YouTube'));
      }
    });

    test('identifies generic browser when window title is not YouTube', () {
      final result = AppIdentityRules.identify('google-chrome',
          'GitHub - Adamskiee/diti: Focus Timer - Google Chrome');
      expect(result.appName, equals('Google Chrome'));
      expect(result.category, equals('Browser'));
    });

    test('identifies code editors and IDEs', () {
      final codeResult = AppIdentityRules.identify(
          'code', 'active_timer_controller.dart - diti - Visual Studio Code');
      expect(codeResult.appName, equals('VS Code'));
      expect(codeResult.category, equals('Development'));

      final ideaResult = AppIdentityRules.identify(
          'jetbrains-idea', 'diti [~/dev/diti] - ...');
      expect(ideaResult.appName, equals('IDE'));
      expect(ideaResult.category, equals('Development'));
    });

    test('formats unknown applications gracefully', () {
      final result =
          AppIdentityRules.identify('spotify', 'Daft Punk - Around the World');
      expect(result.appName, equals('Spotify'));
      expect(result.category, equals('Other'));
    });
  });
}
