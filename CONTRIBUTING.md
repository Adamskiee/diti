# Contributing to Diti

First off, thank you for considering contributing to Diti! 🎉

Diti is a free, open-source, local-first daily planning and multi-phase routine timer. Our mission is to build a reliable, distraction-free productivity tool that adapts to reality rather than forcing rigid schedules.

Everyone is welcome to contribute—whether you are an experienced Flutter developer, just learning Dart, a designer crafting icons and screenshots, or an end user reporting an edge case. Every contribution matters.

---

## Table of Contents

- [Code of Conduct](#code-of-conduct)
- [How Can I Contribute?](#how-can-i-contribute)
  - [Reporting Bugs](#reporting-bugs)
  - [Suggesting Enhancements](#suggesting-enhancements)
  - [Visuals & Screenshots](#visuals--screenshots)
  - [Improving Documentation](#improving-documentation)
  - [Code Contributions](#code-contributions)
- [Project Architecture](#project-architecture)
- [Development Setup](#development-setup)
- [Running Tests & Quality Assurance](#running-tests--quality-assurance)
- [Git & Pull Request Workflow](#git--pull-request-workflow)
- [Commit Message Guidelines](#commit-message-guidelines)

---

## Code of Conduct

We are committed to providing a welcoming, inclusive, and harassment-free environment for everyone. Please be respectful, constructive, and kind in all discussions, issues, and code reviews.

---

## How Can I Contribute?

### Reporting Bugs

If you encounter unexpected behavior, a crash, or a timer discrepancy:

1. **Check Existing Issues**: Search our [GitHub Issues](https://github.com/Adamskiee/diti/issues) to see if the bug has already been reported.
2. **Submit a New Issue**: If it is not listed, open a new issue with:
   - A clear, descriptive title.
   - Steps to reproduce the bug.
   - Expected vs. actual behavior.
   - Platform information (OS version, Android device/API level, or Linux distribution).
   - Any relevant logs or screenshots.

### Suggesting Enhancements

Have an idea for a new routine type, timer transition, or UI enhancement?
- Open an issue tagged as an enhancement.
- Explain the motivation: what problem does this solve, and how will it benefit users?
- Keep in mind Diti's core principles: **local-first privacy**, **resilient state**, and **simplicity**.

### Visuals & Screenshots

Visual appeal helps persuade users to download and try Diti! If you can capture high-resolution screenshots or create UI demo GIFs on Android or Linux:
- Add them to [`assets/screenshots/`](assets/screenshots/).
- Submit a PR linking them to the main [README.md](README.md).

### Improving Documentation

Documentation improvements are always welcome:
- Fixing typos or outdated instructions.
- Adding setup tips for various Linux distributions.
- Clarifying architectural patterns or adding inline code comments.

### Code Contributions

Ready to write code?
- Pick an unassigned issue or propose a change first so we can discuss the approach.
- Follow our [Development Setup](#development-setup) and [Pull Request Workflow](#git--pull-request-workflow).

---

## Project Architecture

Diti is organized as a modular Flutter monorepo with distinct packages under [`packages/`](packages/) to maintain separation of concerns:

```
diti/
├── assets/                    # Icons, logos, and app screenshots
├── lib/                       # Root Flutter application (UI, views, router, Riverpod state)
├── packages/
│   ├── timer_engine/          # Pure Dart timer state machine, ticks, & phase transitions
│   ├── diti_database/         # SQLite persistence layer powered by Drift & migrations
│   ├── diti_notifications/    # Platform local notifications, channels, & audio alerts
│   └── diti_tracker/          # Analytics aggregator, session metrics, & history
├── test/                      # Root unit, widget, and golden test suite
├── integration_test/          # Desktop (Linux) and emulator integration tests
├── patrol_test/               # E2E Android device tests with permission flows
└── scripts/                   # Installation and release helper scripts
```

### Key Principles

1. **Independent Core Logic**: `timer_engine` contains zero Flutter dependencies—it is pure Dart. All state transitions, durations, and phase calculations are independently testable.
2. **Local-First Persistence**: `diti_database` handles SQLite persistence (`~/Documents/diti.db` on Linux). Data schemas must support non-destructive migrations.
3. **Resilience**: The timer state machine snapshot ensures that timers can accurately calculate elapsed time across pauses, app kills, backgrounding, and device reboots.

---

## Development Setup

### Prerequisites

- **Flutter SDK**: `>= 3.27.0` ([Flutter installation guide](https://docs.flutter.dev/get-started/install))
- **Dart SDK**: `^3.6.0`
- **Linux Desktop Development** (if developing on Linux):
  ```bash
  sudo apt update && sudo apt install -y clang cmake ninja-build pkg-config libgtk-3-dev
  ```
- **Android SDK & Java 17** (if developing/testing for Android)

### Setup Steps

1. **Clone the repository:**
   ```bash
   git clone https://github.com/Adamskiee/diti.git
   cd diti
   ```

2. **Install dependencies across all packages and root:**
   ```bash
   for pkg in packages/*; do
     if [ -f "$pkg/pubspec.yaml" ]; then
       (cd "$pkg" && flutter pub get)
     fi
   done
   flutter pub get
   ```

3. **Verify your Flutter installation:**
   ```bash
   flutter doctor
   ```

4. **Run the app locally:**
   ```bash
   # Linux desktop:
   flutter run -d linux

   # Android (device or emulator):
   flutter run -d <device-id>
   ```

---

## Running Tests & Quality Assurance

Diti maintains a comprehensive test suite covering unit logic, widget rendering, golden UI fidelity, and full platform integration.

| Layer | Command | Scope |
|---|---|---|
| **Static Analysis** | `flutter analyze --fatal-infos` | Enforces zero warnings, hints, or lint errors across the workspace |
| **Modular Packages** | `cd packages/<name> && flutter test` | Pure Dart logic in `timer_engine`, `diti_database`, etc. |
| **Unit & Widget** | `flutter test test/` | Application unit and UI widget behavior |
| **Golden UI Tests** | `flutter test test/goldens` | Visual screenshot regression tests |
| **Update Goldens** | `flutter test --update-goldens test/goldens` | Updates reference golden images (commit `test/goldens/ci/*.png`) |
| **Linux Integration** | `flutter test integration_test -d linux` | End-to-end flows on Linux desktop runner |
| **Android Patrol E2E**| `patrol test` | Android E2E flows testing notifications & permissions |

### Fast Local Verification

Run this one-pass check before pushing your code or opening a PR:

```bash
for pkg in packages/*; do
  if [ -d "$pkg/test" ]; then
    (cd "$pkg" && flutter test)
  fi
done
CI=true flutter test test/
flutter analyze --fatal-infos
```

> [!TIP]
> Setting `CI=true` matches GitHub Actions by validating against cross-platform golden images. Alternatively, run `flutter test --update-goldens test/goldens` to generate local platform golden baselines.

---

## Git & Pull Request Workflow

1. **Create a Topic Branch**:
   Branch off `main` using a descriptive name:
   ```bash
   git checkout main
   git pull origin main
   git checkout -b feat/custom-routine-presets
   # Or for bug fixes:
   git checkout -b fix/negative-timer-overflow
   ```

2. **Make Atomic Changes**:
   Keep commits focused on a single logical change.

3. **Verify Locally**:
   Ensure all tests pass and static analysis is clean (`flutter analyze --fatal-infos`).

4. **Push and Open a Pull Request**:
   Push your branch to GitHub and open a Pull Request against `main`. Fill in the PR description detailing what was changed and how to verify it.

---

## Commit Message Guidelines

We follow [Conventional Commits](https://www.conventionalcommits.org/):

- `feat:` Introduces a new user-facing feature.
- `fix:` Fixes a bug.
- `docs:` Documentation changes only.
- `style:` Code style/formatting changes with no logic impact.
- `refactor:` Code refactoring that neither fixes a bug nor adds a feature.
- `test:` Adding or updating tests.
- `ci:` Changes to CI/CD workflows or scripts.
- `chore:` Maintenance tasks, dependency updates, version bumps.

**Format:**
```
<type>(<optional scope>): <short summary under 72 characters>

[optional body explaining motivation and context]
```

*Example:*
```
feat(timer): run rest timer on negative when awaiting continuation
```

---

Thank you for helping make Diti better for everyone! 🚀
