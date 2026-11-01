from __future__ import annotations

import argparse
import json
from pathlib import Path
import sys
from typing import Any
import yaml

from tool.security.findings import Finding, apply_suppressions, load_findings


def load_masvs_map(map_path: str | Path) -> dict[str, list[str]]:
    p = Path(map_path)
    if not p.exists():
        return {}
    with p.open("r", encoding="utf-8") as f:
        data = yaml.safe_load(f) or {}
    if not isinstance(data, dict):
        return {}
    return data.get("mappings") or {}


def evaluate_gate(findings: list[Finding], mode: str) -> tuple[int, list[str]]:
    failures: list[str] = []
    for f in findings:
        if f.suppressed:
            continue
        # Expired suppression or critical always fails
        if f.rule_id == "expired-suppression" or f.severity.lower() == "critical":
            failures.append(f"[{f.severity.upper()}] {f.tool}:{f.rule_id} at {f.location} - {f.title}")
            continue

        if f.severity.lower() == "high":
            if mode == "release":
                failures.append(f"[{f.severity.upper()}] {f.tool}:{f.rule_id} at {f.location} - {f.title}")
            elif mode == "pr":
                if f.tool in ("gitleaks", "trivy", "suppressions"):
                    failures.append(f"[{f.severity.upper()}] {f.tool}:{f.rule_id} at {f.location} - {f.title}")

    return (1 if failures else 0), failures


def format_markdown_report(findings: list[Finding], failures: list[str], mode: str) -> str:
    status_icon = "❌ **FAILED**" if failures else "✅ **PASSED**"
    lines = [
        f"## 🛡️ Security & MASVS Compliance Report ({mode.upper()} mode)",
        "",
        f"**Gate Status:** {status_icon}",
        "",
    ]
    if failures:
        lines.append("### 🚫 Blocking Violations")
        for fail in failures:
            lines.append(f"- {fail}")
        lines.append("")

    active_findings = [f for f in findings if not f.suppressed]
    suppressed_findings = [f for f in findings if f.suppressed]

    lines.append(f"### 📋 Active Findings ({len(active_findings)})")
    if not active_findings:
        lines.append("_No active findings detected._")
    else:
        lines.append("| Severity | Tool | Rule | Location | MASVS | Title |")
        lines.append("|---|---|---|---|---|---|")
        for f in active_findings:
            masvs_str = ", ".join(f.masvs) if f.masvs else "MASVS-UNMAPPED"
            lines.append(f"| {f.severity.upper()} | {f.tool} | `{f.rule_id}` | `{f.location}` | {masvs_str} | {f.title} |")
    lines.append("")

    if suppressed_findings:
        lines.append(f"### 🛡️ Suppressed Findings ({len(suppressed_findings)})")
        lines.append("| Tool | Rule | Location | Reason |")
        lines.append("|---|---|---|---|")
        for f in suppressed_findings:
            lines.append(f"| {f.tool} | `{f.rule_id}` | `{f.location}` | {f.reason} |")
        lines.append("")

    return "\n".join(lines)


def generate_report(
    findings_dir: str | Path,
    map_path: str | Path,
    suppressions_path: str | Path,
    mode: str,
) -> tuple[int, str, dict[str, Any]]:
    d = Path(findings_dir)
    all_findings: list[Finding] = []

    for f_path in sorted(d.glob("**/findings-*.json")):
        all_findings.extend(load_findings(f_path))

    masvs_map = load_masvs_map(map_path)
    for f in all_findings:
        if not f.masvs and f.rule_id in masvs_map:
            f.masvs = masvs_map[f.rule_id]

    active_findings, expired_findings = apply_suppressions(all_findings, suppressions_path)
    total_findings = active_findings + expired_findings

    status_code, failures = evaluate_gate(total_findings, mode)
    md_report = format_markdown_report(total_findings, failures, mode)
    report_dict = {
        "mode": mode,
        "status": "fail" if status_code != 0 else "pass",
        "failures": failures,
        "findings": [f.to_dict() for f in total_findings],
    }
    return status_code, md_report, report_dict


def main() -> None:
    parser = argparse.ArgumentParser(description="MASVS Report Aggregator and Gate")
    parser.add_argument("--findings-dir", required=True)
    parser.add_argument("--map", required=True)
    parser.add_argument("--suppressions", required=True)
    parser.add_argument("--mode", choices=["pr", "release"], default="pr")
    parser.add_argument("--summary", required=False)
    parser.add_argument("--json-out", required=False)
    args = parser.parse_args()

    status_code, md_report, report_dict = generate_report(
        args.findings_dir, args.map, args.suppressions, args.mode
    )

    if args.summary:
        summary_path = Path(args.summary)
        summary_path.parent.mkdir(parents=True, exist_ok=True)
        summary_path.write_text(md_report, encoding="utf-8")
    if args.json_out:
        json_path = Path(args.json_out)
        json_path.parent.mkdir(parents=True, exist_ok=True)
        with json_path.open("w", encoding="utf-8") as f:
            json.dump(report_dict, f, indent=2)

    print(md_report)
    sys.exit(status_code)


if __name__ == "__main__":
    main()
