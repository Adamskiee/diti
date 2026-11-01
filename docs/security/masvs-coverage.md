# OWASP MASVS v2 (MAS-L1) Coverage Matrix

This document tracks the coverage of OWASP Mobile Application Security Verification Standard (MASVS v2) controls for Diti under the **MAS-L1** (Standard Security) profile.

## Control Matrix

| Control ID | Category | Status | Automated By | Verification / Notes |
|---|---|---|---|---|
| **MASVS-STORAGE-1** | Storage | **Automated** | `gitleaks`, `apk-checks` | Scans for hardcoded credentials and tokens in code and compiled binaries. |
| **MASVS-STORAGE-2** | Storage | **Automated** | `manifest_check` | Enforces `android:dataExtractionRules` excluding cloud backups. |
| **MASVS-CRYPTO-1** | Cryptography | **N/A** | - | Diti performs no custom encryption; relies on platform keystore. |
| **MASVS-AUTH-1** | Authentication | **N/A** | - | Diti is an offline-first local timer/analytics app without authentication endpoints. |
| **MASVS-NETWORK-1** | Network | **Automated** | `manifest_check` | Enforces `networkSecurityConfig` blocking all cleartext HTTP traffic. |
| **MASVS-PLATFORM-1** | Platform | **Automated** | `manifest_check`, `permissions_check` | Enforces component permission protection and strict permissions allowlisting. |
| **MASVS-CODE-1** | Code Quality | **Automated** | `ci.yml` (`quality`) | Enforces `flutter analyze --fatal-infos` on all code. |
| **MASVS-CODE-3** | Code Quality | **Automated** | `deps` (Trivy) | Scans `pubspec.lock` dependencies for CVEs with fixes. |
| **MASVS-RESILIENCE-2** | Resilience | **Automated** | `sign_check` | Blocks artifacts signed with debug certificates during release. |
| **MASVS-RESILIENCE-3** | Resilience | **Automated** | `obfuscation_check` | Confirms `--obfuscate` stripped Dart symbols from `libapp.so`. |
| **MASVS-RESILIENCE-4** | Resilience | **Automated** | `manifest_check` | Enforces `android:debuggable="false"` in release builds. |
| **MASVS-PRIVACY-1** | Privacy | **Automated** | `permissions_check` | Blocks unreviewed privacy-sensitive permission additions. |

## Known Gaps & Future Work
- **Gradle dependency scanning**: Trivy currently scans Dart dependencies. Direct Java/Kotlin dependencies are reviewed via MobSF.
