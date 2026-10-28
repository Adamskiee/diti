import 'app_usage_summary.dart';

class AppIdentityRules {
  static const Set<String> _terminals = {
    'alacritty',
    'kitty',
    'gnome-terminal',
    'konsole',
    'xterm',
    'foot',
    'wezterm',
    'tilix',
  };

  static const Map<String, String> _browsers = {
    'google-chrome': 'Google Chrome',
    'chrome': 'Google Chrome',
    'chromium': 'Chromium',
    'firefox': 'Firefox',
    'brave-browser': 'Brave',
    'microsoft-edge': 'Edge',
    'opera': 'Opera',
  };

  static AppIdentityResult identify(String rawClass, String rawTitle) {
    final lowerClass = rawClass.trim().toLowerCase();
    final lowerTitle = rawTitle.trim().toLowerCase();

    // 1. Terminal check
    for (final term in _terminals) {
      if (lowerClass.contains(term)) {
        return const AppIdentityResult(
          appName: 'Terminal',
          category: 'Terminal',
          sampleTitle: 'Terminal',
        );
      }
    }

    // 2. Browser check (with YouTube isolation)
    for (final entry in _browsers.entries) {
      if (lowerClass.contains(entry.key)) {
        final browserName = entry.value;
        if (lowerTitle.contains('youtube') || lowerTitle.contains('youtu.be')) {
          return AppIdentityResult(
            appName: browserName,
            category: 'YouTube',
            sampleTitle: 'YouTube',
          );
        }
        return AppIdentityResult(
          appName: browserName,
          category: 'Browser',
          sampleTitle: rawTitle.isNotEmpty ? rawTitle : browserName,
        );
      }
    }

    // 3. Code editors & IDEs
    if (lowerClass.contains('code') || lowerClass.contains('vscodium')) {
      return const AppIdentityResult(
        appName: 'VS Code',
        category: 'Development',
        sampleTitle: 'VS Code',
      );
    }
    if (lowerClass.contains('idea') ||
        lowerClass.contains('studio') ||
        lowerClass.contains('clion') ||
        lowerClass.contains('pycharm') ||
        lowerClass.contains('webstorm')) {
      return const AppIdentityResult(
        appName: 'IDE',
        category: 'Development',
        sampleTitle: 'IDE',
      );
    }

    // 4. Productivity tools
    if (lowerClass.contains('obsidian')) {
      return const AppIdentityResult(
        appName: 'Obsidian',
        category: 'Productivity',
        sampleTitle: 'Obsidian',
      );
    }
    if (lowerClass.contains('notion')) {
      return const AppIdentityResult(
        appName: 'Notion',
        category: 'Productivity',
        sampleTitle: 'Notion',
      );
    }

    // 5. Fallback formatting
    final cleanApp = _capitalize(rawClass.isEmpty ? 'Unknown' : rawClass);
    return AppIdentityResult(
      appName: cleanApp,
      category: 'Other',
      sampleTitle: rawTitle.isNotEmpty ? rawTitle : cleanApp,
    );
  }

  static String _capitalize(String text) {
    if (text.isEmpty) return text;
    final parts = text.split(RegExp(r'[-_\s]+'));
    return parts
        .where((p) => p.isNotEmpty)
        .map((p) => p[0].toUpperCase() + p.substring(1).toLowerCase())
        .join(' ');
  }
}
