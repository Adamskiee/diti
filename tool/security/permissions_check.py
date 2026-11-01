from __future__ import annotations
import xml.etree.ElementTree as ET
from pathlib import Path
import yaml
from tool.security.findings import Finding

ANDROID_NS = "http://schemas.android.com/apk/res/android"

def check_permissions(manifest_path: str | Path, allowlist_path: str | Path) -> list[Finding]:
    m_p = Path(manifest_path)
    a_p = Path(allowlist_path)
    if not m_p.exists() or not a_p.exists():
        return []

    tree = ET.parse(m_p)
    root = tree.getroot()

    with a_p.open("r", encoding="utf-8") as f:
        allowlist_data = yaml.safe_load(f) or {}
    allowed = set(allowlist_data.get("allowed_permissions", []))

    manifest_perms = set()
    for perm in root.findall("uses-permission"):
        name = perm.attrib.get(f"{{{ANDROID_NS}}}name")
        if name:
            manifest_perms.add(name)

    findings = []
    unallowed = manifest_perms - allowed
    for p in sorted(unallowed):
        findings.append(Finding(
            tool="permissions_check",
            rule_id="unallowlisted-permission",
            severity="high",
            title=f"Declared permission '{p}' not in permissions_allowlist.yaml",
            location=f"{m_p}:{p}",
            masvs=["MASVS-PLATFORM-1", "MASVS-PRIVACY-1"],
        ))

    return findings
