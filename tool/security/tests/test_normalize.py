import json
import subprocess
import sys
import tempfile
from pathlib import Path
from tool.security.normalize import normalize_gitleaks, normalize_trivy


def test_normalize_gitleaks_output():
    raw_data = [
        {
            "RuleID": "generic-api-key",
            "Description": "Generic API Key",
            "File": "lib/secrets.dart",
            "StartLine": 12,
            "Secret": "test_token_12345",
        }
    ]
    with tempfile.NamedTemporaryFile("w+", delete=False, suffix=".json") as tmp:
        json.dump(raw_data, tmp)
        tmp.flush()
        findings = normalize_gitleaks(tmp.name)

    assert len(findings) == 1
    assert findings[0].tool == "gitleaks"
    assert findings[0].rule_id == "generic-api-key"
    assert findings[0].severity == "high"
    assert findings[0].location == "lib/secrets.dart:12"
    assert "MASVS-STORAGE-1" in findings[0].masvs


def test_normalize_gitleaks_empty_and_missing():
    assert normalize_gitleaks("non_existent_file.json") == []

    with tempfile.NamedTemporaryFile("w+", delete=False, suffix=".json") as tmp:
        tmp.write("")
        tmp.flush()
        assert normalize_gitleaks(tmp.name) == []

    with tempfile.NamedTemporaryFile("w+", delete=False, suffix=".json") as tmp:
        json.dump({"not": "a list"}, tmp)
        tmp.flush()
        assert normalize_gitleaks(tmp.name) == []


def test_normalize_gitleaks_no_start_line():
    raw_data = [
        {
            "RuleID": "secret-leak",
            "File": "lib/config.dart",
        }
    ]
    with tempfile.NamedTemporaryFile("w+", delete=False, suffix=".json") as tmp:
        json.dump(raw_data, tmp)
        tmp.flush()
        findings = normalize_gitleaks(tmp.name)

    assert len(findings) == 1
    assert findings[0].location == "lib/config.dart"
    assert findings[0].title == "Potential secret leak"


def test_normalize_trivy_output():
    raw_data = {
        "Results": [
            {
                "Target": "pubspec.lock",
                "Vulnerabilities": [
                    {
                        "VulnerabilityID": "CVE-2026-9999",
                        "PkgName": "http",
                        "InstalledVersion": "0.13.0",
                        "FixedVersion": "0.13.5",
                        "Severity": "CRITICAL",
                        "Title": "Remote code execution in HTTP parsing",
                    }
                ],
            }
        ]
    }
    with tempfile.NamedTemporaryFile("w+", delete=False, suffix=".json") as tmp:
        json.dump(raw_data, tmp)
        tmp.flush()
        findings = normalize_trivy(tmp.name)

    assert len(findings) == 1
    assert findings[0].tool == "trivy"
    assert findings[0].rule_id == "CVE-2026-9999"
    assert findings[0].severity == "critical"
    assert findings[0].location == "pubspec.lock:http@0.13.0"
    assert "MASVS-CODE-3" in findings[0].masvs
    assert "Fixed in 0.13.5" in findings[0].title


def test_normalize_trivy_no_fix_and_description():
    raw_data = {
        "Results": [
            {
                "Target": "pubspec.lock",
                "Vulnerabilities": [
                    {
                        "VulnerabilityID": "CVE-2026-1111",
                        "PkgName": "path",
                        "InstalledVersion": "1.8.0",
                        "Severity": "MEDIUM",
                        "Description": "Path traversal issue",
                    }
                ],
            }
        ]
    }
    with tempfile.NamedTemporaryFile("w+", delete=False, suffix=".json") as tmp:
        json.dump(raw_data, tmp)
        tmp.flush()
        findings = normalize_trivy(tmp.name)

    assert len(findings) == 1
    assert findings[0].severity == "medium"
    assert "No fix available" in findings[0].title
    assert "Path traversal issue" in findings[0].title


def test_normalize_cli(tmp_path: Path):
    gitleaks_input = tmp_path / "gitleaks.json"
    gitleaks_output = tmp_path / "gitleaks_out.json"
    raw_data = [
        {
            "RuleID": "aws-key",
            "Description": "AWS Access Key",
            "File": "config.env",
            "StartLine": 5,
        }
    ]
    gitleaks_input.write_text(json.dumps(raw_data), encoding="utf-8")

    res = subprocess.run(
        [
            sys.executable,
            "-m",
            "tool.security.normalize",
            "--tool",
            "gitleaks",
            "--input",
            str(gitleaks_input),
            "--output",
            str(gitleaks_output),
        ],
        capture_output=True,
        text=True,
    )
    assert res.returncode == 0
    assert gitleaks_output.exists()
    out_data = json.loads(gitleaks_output.read_text(encoding="utf-8"))
    assert len(out_data) == 1
    assert out_data[0]["rule_id"] == "aws-key"
