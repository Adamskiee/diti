from __future__ import annotations
import argparse
import json
from pathlib import Path
from typing import Any
from tool.security.findings import Finding, save_findings


def normalize_gitleaks(path: str | Path) -> list[Finding]:
    p = Path(path)
    if not p.exists() or p.stat().st_size == 0:
        return []
    with p.open("r", encoding="utf-8") as f:
        data = json.load(f)
    if not isinstance(data, list):
        return []

    findings = []
    for item in data:
        rule_id = item.get("RuleID", "secret-leak")
        desc = item.get("Description", "Potential secret leak")
        file_path = item.get("File", "")
        start_line = item.get("StartLine", 0)
        location = f"{file_path}:{start_line}" if start_line else file_path
        findings.append(
            Finding(
                tool="gitleaks",
                rule_id=rule_id,
                severity="high",
                title=desc,
                location=location,
                masvs=["MASVS-STORAGE-1", "MASVS-CODE"],
            )
        )
    return findings


def normalize_trivy(path: str | Path) -> list[Finding]:
    p = Path(path)
    if not p.exists() or p.stat().st_size == 0:
        return []
    with p.open("r", encoding="utf-8") as f:
        data = json.load(f)
    if not isinstance(data, dict):
        return []

    findings = []
    results = data.get("Results", []) or []
    for res in results:
        target = res.get("Target", "lockfile")
        vulns = res.get("Vulnerabilities", []) or []
        for v in vulns:
            vuln_id = v.get("VulnerabilityID", "UNKNOWN-CVE")
            pkg_name = v.get("PkgName", "")
            version = v.get("InstalledVersion", "")
            fixed_version = v.get("FixedVersion", "")
            severity = v.get("Severity", "HIGH").lower()
            title = v.get("Title") or v.get("Description", f"Vulnerable dependency: {pkg_name}")
            location = f"{target}:{pkg_name}@{version}"

            reason = f"Fixed in {fixed_version}" if fixed_version else "No fix available"
            findings.append(
                Finding(
                    tool="trivy",
                    rule_id=vuln_id,
                    severity=severity,
                    title=f"{pkg_name}: {title} ({reason})",
                    location=location,
                    masvs=["MASVS-CODE-3"],
                )
            )
    return findings


def main() -> None:
    parser = argparse.ArgumentParser(description="Normalize scanner JSON into standard findings format.")
    parser.add_argument("--tool", choices=["gitleaks", "trivy"], required=True)
    parser.add_argument("--input", required=True)
    parser.add_argument("--output", required=True)
    args = parser.parse_args()

    if args.tool == "gitleaks":
        findings = normalize_gitleaks(args.input)
    elif args.tool == "trivy":
        findings = normalize_trivy(args.input)
    else:
        findings = []

    save_findings(findings, args.output)
    print(f"Normalized {len(findings)} findings from {args.tool} to {args.output}")


if __name__ == "__main__":
    main()
