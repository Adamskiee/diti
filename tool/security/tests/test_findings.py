import datetime
import json
import tempfile
from pathlib import Path
import pytest
from tool.security.findings import Finding, load_findings, save_findings, apply_suppressions

def test_finding_serialization():
    f = Finding(
        tool="test_tool",
        rule_id="RULE-1",
        severity="high",
        title="Test issue",
        location="AndroidManifest.xml:10",
        masvs=["MASVS-STORAGE-1"],
    )
    with tempfile.NamedTemporaryFile("w+", delete=False, suffix=".json") as tmp:
        save_findings([f], tmp.name)
        loaded = load_findings(tmp.name)
    assert len(loaded) == 1
    assert loaded[0].tool == "test_tool"
    assert loaded[0].severity == "high"
    assert loaded[0].masvs == ["MASVS-STORAGE-1"]
    assert loaded[0].suppressed is False

def test_finding_from_dict_severity_none_or_missing():
    f_none = Finding.from_dict({"tool": "t", "severity": None})
    assert f_none.severity == "info"

    f_missing = Finding.from_dict({"tool": "t"})
    assert f_missing.severity == "info"

def test_suppression_active():
    f = Finding(
        tool="apk_manifest",
        rule_id="manifest-debuggable",
        severity="critical",
        title="Debuggable enabled",
        location="AndroidManifest.xml",
        masvs=["MASVS-RESILIENCE-4"],
    )
    suppressions_content = """
suppressions:
  - tool: "apk_manifest"
    rule_id: "manifest-debuggable"
    reason: "Testing in staging"
    expires: "2026-12-31"
"""
    with tempfile.NamedTemporaryFile("w+", delete=False, suffix=".yaml") as tmp:
        tmp.write(suppressions_content)
        tmp.flush()
        active, expired = apply_suppressions([f], tmp.name, now=datetime.date(2026, 11, 1))

    assert len(active) == 1
    assert active[0].suppressed is True
    assert active[0].reason == "Testing in staging"
    assert len(expired) == 0

def test_suppression_expired_generates_finding():
    f = Finding(
        tool="apk_manifest",
        rule_id="manifest-debuggable",
        severity="critical",
        title="Debuggable enabled",
        location="AndroidManifest.xml",
        masvs=["MASVS-RESILIENCE-4"],
    )
    suppressions_content = """
suppressions:
  - tool: "apk_manifest"
    rule_id: "manifest-debuggable"
    reason: "Old exemption"
    expires: "2026-10-01"
"""
    with tempfile.NamedTemporaryFile("w+", delete=False, suffix=".yaml") as tmp:
        tmp.write(suppressions_content)
        tmp.flush()
        active, expired_findings = apply_suppressions([f], tmp.name, now=datetime.date(2026, 11, 1))

    assert active[0].suppressed is False
    assert len(expired_findings) == 1
    assert expired_findings[0].tool == "suppressions"
    assert expired_findings[0].rule_id == "expired-suppression"
    assert expired_findings[0].severity == "high"

def test_load_findings_missing_or_empty():
    assert load_findings("/nonexistent/path/findings.json") == []
    with tempfile.NamedTemporaryFile("w+", delete=False, suffix=".json") as tmp:
        tmp.write("")
        tmp.flush()
        assert load_findings(tmp.name) == []

def test_suppression_wildcard_and_location():
    f1 = Finding(
        tool="gitleaks",
        rule_id="generic-api-key",
        severity="critical",
        title="Secret leaked",
        location="test/fixtures/key.dart:12",
    )
    f2 = Finding(
        tool="mobsf",
        rule_id="other-rule",
        severity="low",
        title="Other",
        location="lib/main.dart",
    )
    suppressions_content = """
suppressions:
  - tool: "*"
    rule_id: "generic-api-key"
    location: "test/fixtures/"
    reason: "Dummy test key in test fixtures"
    expires: "2026-12-31"
"""
    with tempfile.NamedTemporaryFile("w+", delete=False, suffix=".yaml") as tmp:
        tmp.write(suppressions_content)
        tmp.flush()
        active, expired = apply_suppressions([f1, f2], tmp.name, now=datetime.date(2026, 11, 1))

    assert active[0].suppressed is True
    assert active[0].reason == "Dummy test key in test fixtures"
    assert active[1].suppressed is False
    assert len(expired) == 0

def test_suppression_missing_reason_or_expires_raises():
    f = Finding("tool", "rule", "high", "title", "loc")
    content = """
suppressions:
  - tool: "tool"
    rule_id: "rule"
"""
    with tempfile.NamedTemporaryFile("w+", delete=False, suffix=".yaml") as tmp:
        tmp.write(content)
        tmp.flush()
        with pytest.raises(ValueError, match="missing mandatory reason or expires"):
            apply_suppressions([f], tmp.name, now=datetime.date(2026, 11, 1))


def test_suppression_empty_block_handled_gracefully():
    f = Finding("tool", "rule", "high", "title", "loc")
    content = "suppressions:\n"
    with tempfile.NamedTemporaryFile("w+", delete=False, suffix=".yaml") as tmp:
        tmp.write(content)
        tmp.flush()
        active, expired = apply_suppressions([f], tmp.name, now=datetime.date(2026, 11, 1))

    assert len(active) == 1
    assert active[0].suppressed is False
    assert len(expired) == 0
