from __future__ import annotations
from pathlib import Path
from tool.security.findings import Finding

def check_obfuscation(strings_output_path: str | Path, sentinels_path: str | Path) -> list[Finding]:
    s_p = Path(strings_output_path)
    sent_p = Path(sentinels_path)
    if not s_p.exists() or not sent_p.exists():
        return []

    content = s_p.read_text(encoding="utf-8", errors="ignore")
    sentinels = [line.strip() for line in sent_p.read_text(encoding="utf-8", errors="ignore").splitlines() if line.strip() and not line.startswith("#")]

    findings = []
    found_symbols = [sym for sym in sentinels if sym in content]

    if found_symbols:
        findings.append(Finding(
            tool="obfuscation_check",
            rule_id="unobfuscated-symbols",
            severity="high",
            title=f"Discovered unobfuscated symbol names in binary: {', '.join(found_symbols)}",
            location=str(s_p),
            masvs=["MASVS-RESILIENCE-3"],
        ))

    return findings
