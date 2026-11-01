from __future__ import annotations

from pathlib import Path
from unittest.mock import MagicMock, patch

import pytest
import requests

from tool.security.findings import load_findings
from tool.security.mobsf_scan import main, parse_mobsf_report, scan_apk


def test_parse_mobsf_report():
    sample_report = {
        "manifest_analysis": {
            "manifest_findings": [
                {
                    "rule": "app_is_debuggable",
                    "severity": "high",
                    "title": "Application is Debuggable",
                    "description": "Debugging was enabled on the app.",
                }
            ]
        },
        "code_analysis": {
            "findings": {
                "android_logging": {
                    "metadata": {
                        "severity": "info",
                        "description": "App logs information",
                    },
                    "files": {"MainActivity.kt": "12,15"},
                }
            }
        },
    }
    findings = parse_mobsf_report(sample_report)
    assert len(findings) == 2
    high_f = next(f for f in findings if f.severity == "high")
    assert high_f.tool == "mobsf"
    assert high_f.rule_id == "app_is_debuggable"
    assert high_f.location == "AndroidManifest.xml"

    info_f = next(f for f in findings if f.severity == "info")
    assert info_f.tool == "mobsf"
    assert info_f.rule_id == "android_logging"
    assert info_f.location == "MainActivity.kt"


def test_parse_mobsf_report_defaults_and_edge_cases():
    # Empty report
    assert parse_mobsf_report({}) == []

    # Report with empty / None sections
    assert parse_mobsf_report({"manifest_analysis": None, "code_analysis": None}) == []

    # Manifest finding with fallback rule and title
    report = {
        "manifest_analysis": {
            "manifest_findings": [
                {
                    # No rule -> mobsf-manifest-rule
                    # No title -> description
                    "description": "Fallback description",
                    "severity": "WARNING",
                },
                {
                    # No title and no description -> default
                },
            ]
        },
        "code_analysis": {
            "findings": {
                "rule_no_files": {
                    "metadata": {
                        "severity": "LOW",
                    },
                    "files": {},
                },
                "non_dict_rule": "invalid_value",
            }
        },
    }
    findings = parse_mobsf_report(report)
    assert len(findings) == 3

    f1 = findings[0]
    assert f1.rule_id == "mobsf-manifest-rule"
    assert f1.title == "Fallback description"
    assert f1.severity == "warning"

    f2 = findings[1]
    assert f2.rule_id == "mobsf-manifest-rule"
    assert f2.title == "Manifest finding"
    assert f2.severity == "info"

    f3 = findings[2]
    assert f3.rule_id == "rule_no_files"
    assert f3.title == "rule_no_files"
    assert f3.severity == "low"
    assert f3.location == "source"


def test_parse_mobsf_report_list_manifest_analysis():
    sample_report = {
        "manifest_analysis": [
            {
                "title": "App is debuggable",
                "stat": "high",
                "desc": "android:debuggable is set to true",
            },
            {
                "rule": "allow_backup",
                "severity": "warning",
                "description": "Backup is allowed",
            },
            "invalid_non_dict_entry",
        ],
        "code_analysis": {},
    }
    findings = parse_mobsf_report(sample_report)
    assert len(findings) == 2

    f1 = findings[0]
    assert f1.tool == "mobsf"
    assert f1.rule_id == "App is debuggable"
    assert f1.severity == "high"
    assert f1.title == "App is debuggable"
    assert f1.location == "AndroidManifest.xml"

    f2 = findings[1]
    assert f2.tool == "mobsf"
    assert f2.rule_id == "allow_backup"
    assert f2.severity == "warning"
    assert f2.title == "Backup is allowed"
    assert f2.location == "AndroidManifest.xml"


def test_scan_apk(tmp_path: Path):
    dummy_apk = tmp_path / "app-release.apk"
    dummy_apk.write_bytes(b"dummy apk content")

    mock_upload_res = MagicMock()
    mock_upload_res.json.return_value = {"hash": "abc123hash", "scan_type": "apk"}

    mock_scan_res = MagicMock()
    mock_scan_res.json.return_value = {"status": "ok"}

    mock_report_res = MagicMock()
    mock_report_res.json.return_value = {"manifest_analysis": {}, "code_analysis": {}}

    with patch("requests.post") as mock_post:
        mock_post.side_effect = [mock_upload_res, mock_scan_res, mock_report_res]

        report = scan_apk("http://localhost:8000/", "test-token", dummy_apk)

        assert report == {"manifest_analysis": {}, "code_analysis": {}}
        assert mock_post.call_count == 3

        # Call 1: upload
        upload_call = mock_post.call_args_list[0]
        assert upload_call.args[0] == "http://localhost:8000/api/v1/upload"
        assert upload_call.kwargs["headers"] == {"Authorization": "test-token"}
        assert "file" in upload_call.kwargs["files"]
        assert upload_call.kwargs["timeout"] == 300

        # Call 2: scan
        scan_call = mock_post.call_args_list[1]
        assert scan_call.args[0] == "http://localhost:8000/api/v1/scan"
        assert scan_call.kwargs["data"] == {"hash": "abc123hash", "scan_type": "apk"}
        assert scan_call.kwargs["timeout"] == 300

        # Call 3: report_json
        report_call = mock_post.call_args_list[2]
        assert report_call.args[0] == "http://localhost:8000/api/v1/report_json"
        assert report_call.kwargs["data"] == {"hash": "abc123hash"}
        assert report_call.kwargs["timeout"] == 300


def test_scan_apk_raises_on_http_error(tmp_path: Path):
    dummy_apk = tmp_path / "test.apk"
    dummy_apk.write_bytes(b"dummy")

    mock_res = MagicMock()
    mock_res.raise_for_status.side_effect = requests.HTTPError("401 Unauthorized")

    with (
        patch("requests.post", return_value=mock_res),
        pytest.raises(requests.HTTPError),
    ):
        scan_apk("http://localhost:8000", "bad-key", dummy_apk)


def test_main_cli(tmp_path: Path):
    output_file = tmp_path / "mobsf-findings.json"
    sample_report = {
        "manifest_analysis": {
            "manifest_findings": [
                {
                    "rule": "debuggable",
                    "severity": "high",
                    "title": "Debuggable App",
                }
            ]
        }
    }

    test_args = [
        "mobsf_scan.py",
        "--server",
        "http://localhost:8000",
        "--key",
        "secret-key",
        "--apk",
        "/path/to/test.apk",
        "--output",
        str(output_file),
    ]

    with (
        patch("sys.argv", test_args),
        patch("tool.security.mobsf_scan.scan_apk", return_value=sample_report) as mock_scan,
    ):
        main()
        mock_scan.assert_called_once_with("http://localhost:8000", "secret-key", "/path/to/test.apk")

    assert output_file.exists()
    findings = load_findings(output_file)
    assert len(findings) == 1
    assert findings[0].rule_id == "debuggable"
    assert findings[0].severity == "high"
