from __future__ import annotations
from pathlib import Path
import pytest
from tool.security.manifest_check import check_manifest
from tool.security.sign_check import check_signature
from tool.security.permissions_check import check_permissions
from tool.security.obfuscation_check import check_obfuscation

def test_manifest_check_detects_insecure_flags(tmp_path: Path):
    bad_manifest = """<?xml version="1.0" encoding="utf-8"?>
<manifest xmlns:android="http://schemas.android.com/apk/res/android" package="com.adilabs.diti">
    <application android:debuggable="true" android:allowBackup="true" android:usesCleartextTraffic="true">
        <activity android:name=".MainActivity" android:exported="true">
            <intent-filter>
                <action android:name="android.intent.action.MAIN" />
                <category android:name="android.intent.category.LAUNCHER" />
            </intent-filter>
        </activity>
        <service android:name=".InsecureService" android:exported="true" />
    </application>
</manifest>
"""
    manifest_file = tmp_path / "AndroidManifest.xml"
    manifest_file.write_text(bad_manifest, encoding="utf-8")
    findings = check_manifest(manifest_file)

    rule_ids = {f.rule_id for f in findings}
    assert "manifest-debuggable" in rule_ids
    assert "manifest-backup-unscoped" in rule_ids
    assert "manifest-cleartext-permitted" in rule_ids
    assert "manifest-exported-unprotected" in rule_ids

def test_manifest_check_secure_app(tmp_path: Path):
    good_manifest = """<?xml version="1.0" encoding="utf-8"?>
<manifest xmlns:android="http://schemas.android.com/apk/res/android" package="com.adilabs.diti">
    <application
        android:debuggable="false"
        android:allowBackup="false"
        android:usesCleartextTraffic="false"
        android:networkSecurityConfig="@xml/network_security_config">
        <activity android:name=".MainActivity" android:exported="true">
            <intent-filter>
                <action android:name="android.intent.action.MAIN" />
                <category android:name="android.intent.category.LAUNCHER" />
            </intent-filter>
        </activity>
        <service android:name=".SecureService" android:exported="true" android:permission="com.adilabs.diti.CUSTOM_PERM" />
        <activity android:name=".InternalActivity" android:exported="false" />
    </application>
</manifest>
"""
    manifest_file = tmp_path / "AndroidManifest.xml"
    manifest_file.write_text(good_manifest, encoding="utf-8")
    findings = check_manifest(manifest_file)
    assert len(findings) == 0

def test_manifest_check_missing_manifest(tmp_path: Path):
    missing_file = tmp_path / "NonExistent.xml"
    findings = check_manifest(missing_file)
    assert len(findings) == 1
    assert findings[0].rule_id == "manifest-missing"
    assert findings[0].severity == "critical"

def test_manifest_check_no_application_tag(tmp_path: Path):
    empty_manifest = """<?xml version="1.0" encoding="utf-8"?>
<manifest xmlns:android="http://schemas.android.com/apk/res/android" package="com.adilabs.diti">
</manifest>
"""
    manifest_file = tmp_path / "AndroidManifest.xml"
    manifest_file.write_text(empty_manifest, encoding="utf-8")
    findings = check_manifest(manifest_file)
    assert findings == []

def test_signature_check_detects_debug_keystore(tmp_path: Path):
    debug_certs_output = """Signer #1 certificate DN: CN=Android Debug, O=Android, C=US
Signer #1 certificate SHA-256 digest: 1122334455
Verification passed
"""
    cert_file = tmp_path / "apksigner.txt"
    cert_file.write_text(debug_certs_output, encoding="utf-8")
    findings = check_signature(cert_file)

    assert len(findings) == 1
    assert findings[0].rule_id == "debug-signed-apk"
    assert findings[0].severity == "high"

def test_signature_check_detects_verification_failure(tmp_path: Path):
    failure_output = """DOES NOT VERIFY
Signer #1 certificate DN: CN=Release Key, O=AdiLabs, C=US
"""
    cert_file = tmp_path / "apksigner_fail.txt"
    cert_file.write_text(failure_output, encoding="utf-8")
    findings = check_signature(cert_file)

    rule_ids = {f.rule_id for f in findings}
    assert "signature-verification-failed" in rule_ids
    failed_finding = next(f for f in findings if f.rule_id == "signature-verification-failed")
    assert failed_finding.severity == "critical"

def test_signature_check_missing_or_empty_file(tmp_path: Path):
    missing_file = tmp_path / "missing.txt"
    findings = check_signature(missing_file)
    assert len(findings) == 1
    assert findings[0].rule_id == "signature-unverified"

    empty_file = tmp_path / "empty.txt"
    empty_file.write_text("", encoding="utf-8")
    findings_empty = check_signature(empty_file)
    assert len(findings_empty) == 1
    assert findings_empty[0].rule_id == "signature-unverified"

def test_signature_check_valid_release_keystore(tmp_path: Path):
    release_output = """Signer #1 certificate DN: CN=Production Key, O=AdiLabs, C=US
Signer #1 certificate SHA-256 digest: aabbccddeeff
Verification passed
"""
    cert_file = tmp_path / "apksigner_release.txt"
    cert_file.write_text(release_output, encoding="utf-8")
    findings = check_signature(cert_file)
    assert findings == []

def test_permissions_check_detects_unallowed_permission(tmp_path: Path):
    manifest = """<?xml version="1.0" encoding="utf-8"?>
<manifest xmlns:android="http://schemas.android.com/apk/res/android">
    <uses-permission android:name="android.permission.INTERNET" />
    <uses-permission android:name="android.permission.CAMERA" />
</manifest>
"""
    allowlist = """
allowed_permissions:
  - "android.permission.INTERNET"
"""
    manifest_file = tmp_path / "AndroidManifest.xml"
    allowlist_file = tmp_path / "permissions_allowlist.yaml"
    manifest_file.write_text(manifest, encoding="utf-8")
    allowlist_file.write_text(allowlist, encoding="utf-8")

    findings = check_permissions(manifest_file, allowlist_file)

    assert len(findings) == 1
    assert findings[0].rule_id == "unallowlisted-permission"
    assert "android.permission.CAMERA" in findings[0].title

def test_permissions_check_all_allowed(tmp_path: Path):
    manifest = """<?xml version="1.0" encoding="utf-8"?>
<manifest xmlns:android="http://schemas.android.com/apk/res/android">
    <uses-permission android:name="android.permission.INTERNET" />
    <uses-permission android:name="android.permission.VIBRATE" />
</manifest>
"""
    allowlist = """
allowed_permissions:
  - "android.permission.INTERNET"
  - "android.permission.VIBRATE"
"""
    manifest_file = tmp_path / "AndroidManifest.xml"
    allowlist_file = tmp_path / "permissions_allowlist.yaml"
    manifest_file.write_text(manifest, encoding="utf-8")
    allowlist_file.write_text(allowlist, encoding="utf-8")

    findings = check_permissions(manifest_file, allowlist_file)
    assert len(findings) == 0

def test_permissions_check_missing_files(tmp_path: Path):
    missing_manifest = tmp_path / "missing.xml"
    missing_allowlist = tmp_path / "missing.yaml"
    assert check_permissions(missing_manifest, missing_allowlist) == []

def test_obfuscation_check_detects_sentinel_leaks(tmp_path: Path):
    strings_output = """
SomeSymbol
PlanBlockConflictDetector
AnotherSymbol
"""
    sentinels = """
PlanBlockConflictDetector
ActiveTimerController
"""
    strings_file = tmp_path / "strings.txt"
    sentinels_file = tmp_path / "sentinels.txt"
    strings_file.write_text(strings_output, encoding="utf-8")
    sentinels_file.write_text(sentinels, encoding="utf-8")

    findings = check_obfuscation(strings_file, sentinels_file)

    assert len(findings) == 1
    assert findings[0].rule_id == "unobfuscated-symbols"
    assert "PlanBlockConflictDetector" in findings[0].title

def test_obfuscation_check_no_leaks(tmp_path: Path):
    strings_output = """
SomeSymbol
AnotherSymbol
CleanBinary
"""
    sentinels = """
# Comments in sentinels
PlanBlockConflictDetector
ActiveTimerController
"""
    strings_file = tmp_path / "strings.txt"
    sentinels_file = tmp_path / "sentinels.txt"
    strings_file.write_text(strings_output, encoding="utf-8")
    sentinels_file.write_text(sentinels, encoding="utf-8")

    findings = check_obfuscation(strings_file, sentinels_file)
    assert findings == []

def test_obfuscation_check_missing_files(tmp_path: Path):
    assert check_obfuscation(tmp_path / "missing.txt", tmp_path / "missing_sent.txt") == []
