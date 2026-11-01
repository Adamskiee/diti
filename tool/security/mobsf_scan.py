from __future__ import annotations

import argparse
from pathlib import Path
from typing import Any

import requests

from tool.security.findings import Finding, save_findings


def parse_mobsf_report(report: dict[str, Any]) -> list[Finding]:
    findings: list[Finding] = []

    # Manifest findings
    manifest_section = report.get("manifest_analysis") or {}
    manifest_findings = manifest_section.get("manifest_findings") or []
    for item in manifest_findings:
        rule_id = item.get("rule", "mobsf-manifest-rule")
        severity = (item.get("severity") or "info").lower()
        title = item.get("title") or item.get("description", "Manifest finding")
        findings.append(
            Finding(
                tool="mobsf",
                rule_id=rule_id,
                severity=severity,
                title=title,
                location="AndroidManifest.xml",
                masvs=[],
            )
        )

    # Code analysis findings
    code_section = report.get("code_analysis") or {}
    code_findings = code_section.get("findings") or {}
    for rule_id, details in code_findings.items():
        if not isinstance(details, dict):
            continue
        meta = details.get("metadata") or {}
        severity = (meta.get("severity") or "info").lower()
        title = meta.get("description") or rule_id
        files = details.get("files") or {}
        loc = next(iter(files.keys())) if files else "source"
        findings.append(
            Finding(
                tool="mobsf",
                rule_id=rule_id,
                severity=severity,
                title=title,
                location=loc,
                masvs=[],
            )
        )

    return findings


def scan_apk(
    server_url: str,
    api_key: str,
    apk_path: str | Path,
    timeout: int = 300,
) -> dict[str, Any]:
    url = server_url.rstrip("/")
    headers = {"Authorization": api_key}
    p = Path(apk_path)

    # 1. Upload
    print(f"Uploading {p.name} to MobSF at {url}...")
    with p.open("rb") as f:
        res = requests.post(
            f"{url}/api/v1/upload",
            headers=headers,
            files={"file": (p.name, f, "application/octet-stream")},
            timeout=timeout,
        )
    res.raise_for_status()
    upload_data = res.json()
    hash_val = upload_data.get("hash")
    scan_type = upload_data.get("scan_type", "apk")

    # 2. Scan
    print(f"Initiating scan for hash: {hash_val}...")
    res = requests.post(
        f"{url}/api/v1/scan",
        headers=headers,
        data={"hash": hash_val, "scan_type": scan_type},
        timeout=timeout,
    )
    res.raise_for_status()

    # 3. Fetch JSON Report
    print("Fetching JSON scan report...")
    res = requests.post(
        f"{url}/api/v1/report_json",
        headers=headers,
        data={"hash": hash_val},
        timeout=timeout,
    )
    res.raise_for_status()
    return res.json()


def main() -> None:
    parser = argparse.ArgumentParser(description="MobSF REST Client")
    parser.add_argument("--server", required=True)
    parser.add_argument("--key", required=True)
    parser.add_argument("--apk", required=True)
    parser.add_argument("--output", required=True)
    args = parser.parse_args()

    report = scan_apk(args.server, args.key, args.apk)
    findings = parse_mobsf_report(report)
    save_findings(findings, args.output)
    print(f"MobSF scan complete: saved {len(findings)} findings to {args.output}")


if __name__ == "__main__":
    main()
