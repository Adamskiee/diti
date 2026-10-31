# Diti

<p align="center">
  <img src="assets/diti-256.png" alt="Diti App Icon" width="128" height="128" />
</p>

[![CI](https://github.com/Adamskiee/aditime/actions/workflows/ci.yml/badge.svg)](https://github.com/Adamskiee/aditime/actions/workflows/ci.yml)

Cross-platform daily planning and multi-phase routine timer built with Flutter.

## Installation & Updates (Linux)

Diti can be installed and updated with a single non-root command. All routines, sessions, and timer data are stored in `~/Documents/diti.db` (existing data from legacy `focus_flow.db` is migrated automatically) and sustained across updates.

### Install
Run the installer script:
```bash
./scripts/install-linux.sh
```
*(Or to build and install directly from your local workspace: `./scripts/install-linux.sh --local`)*

This configures:
- **Executable:** `~/.local/bin/diti` (with `~/.local/bin/aditime` compatibility symlink)
- **Application Menu:** Diti launcher and icon in `~/.local/share/applications/diti.desktop`
- **Updater:** `~/.local/bin/diti-update` (or `diti --update`)

### Updating
Whenever a new release is published, update with one command:
```bash
diti-update
# Or:
diti --update
```
Your routines, plans, and history stored in `~/Documents/diti.db` remain fully intact.

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

## Running Tests

| Layer | Command |
|---|---|
| Unit + widget + golden | `flutter test test/` |
| Update goldens | `flutter test --update-goldens test/goldens` (commit `goldens/ci/*.png`) |
| Package tests | `cd packages/<name> && flutter test` |
| Integration (Linux) | `flutter test integration_test -d linux` |
| Integration (Android) | `flutter test integration_test -d <emulator-id>` |
| Patrol E2E (Android, API 33+) | `dart pub global activate patrol_cli` then `patrol test` |

CI (`.github/workflows/ci.yml`) runs unit/widget/golden tests first; Linux and Android device tests run only if those pass.

## CI/CD & Releases

Diti features automated CI/CD powered by GitHub Actions:

- **Continuous Integration (`ci.yml`)**: Automatically validates linter rules (`flutter analyze --fatal-infos`) and executes tests across all packages on Pull Requests and pushes to `main`.
- **Automated Releases (`release.yml`)**: Builds, signs, and distributes multi-platform binaries upon pushing version tags (`v*.*.*`) or via manual `workflow_dispatch`.

### Released Binaries
Each GitHub Release includes:
- **Android**:
  - `diti-<version>-android-universal.apk` (universal device compatibility)
  - `diti-<version>-android-arm64-v8a.apk` (optimized 64-bit ARM)
  - `diti-<version>-android-armeabi-v7a.apk` (32-bit legacy ARM)
  - `diti-<version>-android-x86_64.apk` (emulators & x86_64 tablets)
  - `diti-<version>-android.aab` (Google Play App Bundle)
- **Linux Desktop**:
  - `diti-<version>-linux-x86_64.AppImage` (standalone portable executable)
  - `diti-<version>-linux-x86_64.tar.gz` (bundled directory archive)
- **Verification**:
  - `checksums.txt` (SHA256 integrity hashes)

### Android Keystore Configuration (GitHub Secrets)
To configure production release signing in your GitHub repository, configure these repository secrets under **Settings > Secrets and variables > Actions**:
- `ANDROID_KEYSTORE_BASE64`: Base64 string of the release keystore file (`base64 -w 0 your.keystore`).
- `ANDROID_KEYSTORE_PASSWORD`: Keystore password.
- `ANDROID_KEY_ALIAS`: Alias for the release key.
- `ANDROID_KEY_PASSWORD`: Password for the key.

*Note: If secrets are not configured, builds automatically and safely fall back to debug signing.*
