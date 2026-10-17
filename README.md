# Aditime (Focus Flow)

[![CI](https://github.com/Adamskiee/aditime/actions/workflows/ci.yml/badge.svg)](https://github.com/Adamskiee/aditime/actions/workflows/ci.yml)

Cross-platform daily planning and multi-phase routine timer built with Flutter.

## Getting Started

### Prerequisites
- [Flutter SDK](https://docs.flutter.dev/get-started/install) (>= 3.27.0)
- Dart SDK (^3.6.0)

### Local Setup
Fetch dependencies across all packages and the root application:
```bash
for pkg in packages/*; do
  if [ -f "$pkg/pubspec.yaml" ]; then
    (cd "$pkg" && flutter pub get)
  fi
done
flutter pub get
```

### Running Tests & Linting
```bash
for pkg in packages/*; do
  if [ -d "$pkg/test" ]; then
    (cd "$pkg" && flutter test)
  fi
done
flutter test test/
flutter analyze --fatal-infos
```

## CI/CD & Releases

Aditime features automated CI/CD powered by GitHub Actions:

- **Continuous Integration (`ci.yml`)**: Automatically validates linter rules (`flutter analyze --fatal-infos`) and executes tests across all packages on Pull Requests and pushes to `main`.
- **Automated Releases (`release.yml`)**: Builds, signs, and distributes multi-platform binaries upon pushing version tags (`v*.*.*`) or via manual `workflow_dispatch`.

### Released Binaries
Each GitHub Release includes:
- **Android**:
  - `aditime-<version>-android-universal.apk` (universal device compatibility)
  - `aditime-<version>-android-arm64-v8a.apk` (optimized 64-bit ARM)
  - `aditime-<version>-android-armeabi-v7a.apk` (32-bit legacy ARM)
  - `aditime-<version>-android-x86_64.apk` (emulators & x86_64 tablets)
  - `aditime-<version>-android.aab` (Google Play App Bundle)
- **Linux Desktop**:
  - `aditime-<version>-linux-x86_64.AppImage` (standalone portable executable)
  - `aditime-<version>-linux-x86_64.tar.gz` (bundled directory archive)
- **Verification**:
  - `checksums.txt` (SHA256 integrity hashes)

### Android Keystore Configuration (GitHub Secrets)
To configure production release signing in your GitHub repository, configure these repository secrets under **Settings > Secrets and variables > Actions**:
- `ANDROID_KEYSTORE_BASE64`: Base64 string of the release keystore file (`base64 -w 0 your.keystore`).
- `ANDROID_KEYSTORE_PASSWORD`: Keystore password.
- `ANDROID_KEY_ALIAS`: Alias for the release key.
- `ANDROID_KEY_PASSWORD`: Password for the key.

*Note: If secrets are not configured, builds automatically and safely fall back to debug signing.*
