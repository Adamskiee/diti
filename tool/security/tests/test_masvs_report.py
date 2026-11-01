import json
import sys
from pathlib import Path
import pytest
from tool.security.findings import Finding, save_findings
from tool.security.masvs_report import (
    evaluate_gate,
    format_markdown_report,
    generate_report,
    load_masvs_map,
    main,
)

def test_evaluate_gate_pr_mode():
    f_high_gitleaks = Finding("gitleaks", "key", "high", "Key leak", "lib/a.dart")
    f_high_mobsf = Finding("mobsf", "mobsf-rule", "high", "MobSF advisory", "AndroidManifest.xml")
    f_high_trivy = Finding("trivy", "CVE-2023-1234", "high", "Trivy vuln", "pubspec.lock")
    f_critical_mobsf = Finding("mobsf", "critical-rule", "critical", "Critical mobsf issue", "AndroidManifest.xml")
    f_suppressed_gitleaks = Finding("gitleaks", "key", "high", "Key leak", "lib/a.dart", suppressed=True, reason="whitelisted")
    f_expired = Finding("suppressions", "expired-suppression", "high", "Expired suppression", "suppressions.yaml")

    # In PR mode: Gitleaks high blocks
    status_code, failures = evaluate_gate([f_high_gitleaks], mode="pr")
    assert status_code != 0
    assert len(failures) == 1

    # In PR mode: Trivy high blocks
    status_code, failures = evaluate_gate([f_high_trivy], mode="pr")
    assert status_code != 0
    assert len(failures) == 1

    # In PR mode: MobSF high is advisory (does NOT block)
    status_code, failures = evaluate_gate([f_high_mobsf], mode="pr")
    assert status_code == 0
    assert len(failures) == 0

    # In PR mode: Critical MobSF DOES block
    status_code, failures = evaluate_gate([f_critical_mobsf], mode="pr")
    assert status_code != 0
    assert len(failures) == 1

    # In PR mode: Expired suppression blocks
    status_code, failures = evaluate_gate([f_expired], mode="pr")
    assert status_code != 0
    assert len(failures) == 1

    # Suppressed high finding does NOT block
    status_code, failures = evaluate_gate([f_suppressed_gitleaks], mode="pr")
    assert status_code == 0
    assert len(failures) == 0


def test_evaluate_gate_release_mode():
    f_high_mobsf = Finding("mobsf", "mobsf-rule", "high", "MobSF high", "AndroidManifest.xml")
    f_high_gitleaks = Finding("gitleaks", "key", "high", "Key leak", "lib/a.dart")
    f_low = Finding("mobsf", "info-rule", "low", "Info note", "lib/b.dart")

    # In Release mode: MobSF high blocks
    status_code, failures = evaluate_gate([f_high_mobsf], mode="release")
    assert status_code != 0
    assert len(failures) == 1

    # In Release mode: Gitleaks high blocks
    status_code, failures = evaluate_gate([f_high_gitleaks], mode="release")
    assert status_code != 0

    # Low severity does not block
    status_code, failures = evaluate_gate([f_low], mode="release")
    assert status_code == 0


def test_load_masvs_map(tmp_path):
    # Non-existent path returns empty dict
    assert load_masvs_map(tmp_path / "does_not_exist.yaml") == {}

    # Valid yaml
    map_file = tmp_path / "map.yaml"
    map_file.write_text("mappings:\n  rule-1: ['MASVS-STORAGE-1']\n", encoding="utf-8")
    mapping = load_masvs_map(map_file)
    assert mapping == {"rule-1": ["MASVS-STORAGE-1"]}


def test_format_markdown_report():
    findings = [
        Finding("gitleaks", "key", "high", "Key leak", "lib/a.dart", masvs=["MASVS-STORAGE-1"]),
        Finding("mobsf", "rule", "low", "Low issue", "lib/b.dart", masvs=[]),
        Finding("trivy", "vuln", "medium", "Vuln", "pubspec.lock", suppressed=True, reason="False positive"),
    ]
    failures = ["[HIGH] gitleaks:key at lib/a.dart - Key leak"]

    md = format_markdown_report(findings, failures, mode="pr")
    assert "## 🛡️ Security & MASVS Compliance Report (PR mode)" in md
    assert "❌ **FAILED**" in md
    assert "### 🚫 Blocking Violations" in md
    assert "[HIGH] gitleaks:key at lib/a.dart - Key leak" in md
    assert "### 📋 Active Findings (2)" in md
    assert "MASVS-STORAGE-1" in md
    assert "MASVS-UNMAPPED" in md
    assert "### 🛡️ Suppressed Findings (1)" in md
    assert "False positive" in md

    # Passed case
    md_passed = format_markdown_report([], [], mode="release")
    assert "✅ **PASSED**" in md_passed
    assert "_No active findings detected._" in md_passed
    assert "### 🚫 Blocking Violations" not in md_passed


def test_generate_report(tmp_path):
    findings_dir = tmp_path / "findings"
    findings_dir.mkdir()
    
    sub_dir = findings_dir / "tool_outputs"
    sub_dir.mkdir()

    # Create findings files
    f1 = Finding("gitleaks", "generic-api-key", "high", "Hardcoded API key", "lib/env.dart")
    save_findings([f1], findings_dir / "findings-gitleaks.json")

    f2 = Finding("mobsf", "allowbackup_is_true", "high", "Backup allowed", "AndroidManifest.xml")
    save_findings([f2], sub_dir / "findings-mobsf.json")

    # Map file
    map_path = tmp_path / "masvs_map.yaml"
    map_path.write_text(
        "mappings:\n"
        "  generic-api-key: ['MASVS-STORAGE-1']\n"
        "  allowbackup_is_true: ['MASVS-STORAGE-2']\n",
        encoding="utf-8",
    )

    # Suppressions file (empty)
    suppressions_path = tmp_path / "suppressions.yaml"
    suppressions_path.write_text("suppressions: []\n", encoding="utf-8")

    # Run generate_report in PR mode:
    # generic-api-key is gitleaks high -> blocks
    # allowbackup_is_true is mobsf high -> advisory in PR mode
    code, md, report_dict = generate_report(findings_dir, map_path, suppressions_path, mode="pr")
    assert code == 1
    assert report_dict["status"] == "fail"
    assert len(report_dict["failures"]) == 1
    assert "gitleaks:generic-api-key" in report_dict["failures"][0]
    
    # Check MASVS mapped
    mapped_rules = {f["rule_id"]: f["masvs"] for f in report_dict["findings"]}
    assert mapped_rules["generic-api-key"] == ["MASVS-STORAGE-1"]
    assert mapped_rules["allowbackup_is_true"] == ["MASVS-STORAGE-2"]

    # Suppressions file with expired entry
    expired_suppressions_path = tmp_path / "suppressions_expired.yaml"
    expired_suppressions_path.write_text(
        "suppressions:\n"
        "  - tool: 'gitleaks'\n"
        "    rule_id: 'generic-api-key'\n"
        "    reason: 'Temporary test key'\n"
        "    expires: '2020-01-01'\n",
        encoding="utf-8",
    )

    code_exp, md_exp, report_dict_exp = generate_report(
        findings_dir, map_path, expired_suppressions_path, mode="pr"
    )
    assert code_exp == 1
    assert any("expired-suppression" in fail for fail in report_dict_exp["failures"])


def test_main_cli(tmp_path, monkeypatch, capsys):
    findings_dir = tmp_path / "findings"
    findings_dir.mkdir()
    save_findings([], findings_dir / "findings-empty.json")

    map_path = tmp_path / "masvs_map.yaml"
    map_path.write_text("mappings: {}\n", encoding="utf-8")

    suppressions_path = tmp_path / "suppressions.yaml"
    suppressions_path.write_text("suppressions: []\n", encoding="utf-8")

    summary_file = tmp_path / "summary.md"
    json_out_file = tmp_path / "summary.json"

    monkeypatch.setattr(
        sys,
        "argv",
        [
            "masvs_report.py",
            "--findings-dir", str(findings_dir),
            "--map", str(map_path),
            "--suppressions", str(suppressions_path),
            "--mode", "pr",
            "--summary", str(summary_file),
            "--json-out", str(json_out_file),
        ],
    )

    with pytest.raises(SystemExit) as exc_info:
        main()
    assert exc_info.value.code == 0

    assert summary_file.exists()
    assert "## 🛡️ Security & MASVS Compliance Report (PR mode)" in summary_file.read_text(encoding="utf-8")

    assert json_out_file.exists()
    out_data = json.loads(json_out_file.read_text(encoding="utf-8"))
    assert out_data["status"] == "pass"
    assert out_data["mode"] == "pr"
