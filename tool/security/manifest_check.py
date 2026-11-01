from __future__ import annotations
import xml.etree.ElementTree as ET
from pathlib import Path
from tool.security.findings import Finding

ANDROID_NS = "http://schemas.android.com/apk/res/android"


def check_manifest(manifest_path: str | Path) -> list[Finding]:
    p = Path(manifest_path)
    if not p.exists():
        return [Finding("manifest_check", "manifest-missing", "critical", f"Manifest not found: {p}", str(p), ["MASVS-PLATFORM-1"])]

    tree = ET.parse(p)
    root = tree.getroot()
    app = root.find("application")
    findings = []

    if app is None:
        return findings

    debuggable = app.attrib.get(f"{{{ANDROID_NS}}}debuggable")
    if debuggable == "true":
        findings.append(Finding(
            tool="manifest_check",
            rule_id="manifest-debuggable",
            severity="critical",
            title="Application is marked android:debuggable='true'",
            location=str(p),
            masvs=["MASVS-RESILIENCE-4"],
        ))

    data_extraction = app.attrib.get(f"{{{ANDROID_NS}}}dataExtractionRules")
    allow_backup = app.attrib.get(f"{{{ANDROID_NS}}}allowBackup")
    if allow_backup != "false" and not data_extraction:
        findings.append(Finding(
            tool="manifest_check",
            rule_id="manifest-backup-unscoped",
            severity="high",
            title="Application allows backup without scoping dataExtractionRules",
            location=str(p),
            masvs=["MASVS-STORAGE-2"],
        ))

    cleartext = app.attrib.get(f"{{{ANDROID_NS}}}usesCleartextTraffic")
    net_config = app.attrib.get(f"{{{ANDROID_NS}}}networkSecurityConfig")
    if cleartext == "true" or not net_config:
        findings.append(Finding(
            tool="manifest_check",
            rule_id="manifest-cleartext-permitted",
            severity="high",
            title="usesCleartextTraffic='true' or missing networkSecurityConfig",
            location=str(p),
            masvs=["MASVS-NETWORK-1"],
        ))

    # Check exported components without permission
    for tag in ("activity", "service", "receiver", "provider"):
        for elem in app.findall(tag):
            exported = elem.attrib.get(f"{{{ANDROID_NS}}}exported")
            name = elem.attrib.get(f"{{{ANDROID_NS}}}name", tag)
            permission = elem.attrib.get(f"{{{ANDROID_NS}}}permission")

            # Check if this is the main launcher activity
            is_launcher = False
            for intent in elem.findall("intent-filter"):
                for action in intent.findall("action"):
                    if action.attrib.get(f"{{{ANDROID_NS}}}name") == "android.intent.action.MAIN":
                        is_launcher = True

            if exported == "true" and not is_launcher and not permission:
                findings.append(Finding(
                    tool="manifest_check",
                    rule_id="manifest-exported-unprotected",
                    severity="high",
                    title=f"Exported component '{name}' is not protected by permission",
                    location=f"{p}:{name}",
                    masvs=["MASVS-PLATFORM-1"],
                ))

    return findings
