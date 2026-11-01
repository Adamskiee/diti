from __future__ import annotations
from pathlib import Path
from tool.security.findings import Finding

def check_signature(apksigner_output_path: str | Path) -> list[Finding]:
    p = Path(apksigner_output_path)
    if not p.exists() or p.stat().st_size == 0:
        return [Finding("sign_check", "signature-unverified", "high", "apksigner output empty or missing", str(p), ["MASVS-RESILIENCE-2"])]

    text = p.read_text(encoding="utf-8", errors="ignore")
    findings = []

    if "CN=Android Debug" in text or "O=Android, C=US" in text:
        findings.append(Finding(
            tool="sign_check",
            rule_id="debug-signed-apk",
            severity="high",
            title="APK is signed with Android Debug certificate",
            location=str(p),
            masvs=["MASVS-RESILIENCE-2"],
        ))

    if "DOES NOT VERIFY" in text or "Verification failed" in text:
        findings.append(Finding(
            tool="sign_check",
            rule_id="signature-verification-failed",
            severity="critical",
            title="APK signature verification failed",
            location=str(p),
            masvs=["MASVS-RESILIENCE-2"],
        ))

    return findings
