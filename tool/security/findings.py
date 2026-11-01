from __future__ import annotations
import dataclasses
import datetime
import json
from pathlib import Path
from typing import Any

@dataclasses.dataclass
class Finding:
    tool: str
    rule_id: str
    severity: str  # critical, high, medium, low, info
    title: str
    location: str
    masvs: list[str] = dataclasses.field(default_factory=list)
    suppressed: bool = False
    reason: str | None = None

    def to_dict(self) -> dict[str, Any]:
        return dataclasses.asdict(self)

    @classmethod
    def from_dict(cls, data: dict[str, Any]) -> Finding:
        return cls(
            tool=data.get("tool", "unknown"),
            rule_id=data.get("rule_id", "unknown"),
            severity=(data.get("severity") or "info").lower(),
            title=data.get("title", ""),
            location=data.get("location", ""),
            masvs=data.get("masvs", []),
            suppressed=data.get("suppressed", False),
            reason=data.get("reason"),
        )

def load_findings(path: str | Path) -> list[Finding]:
    p = Path(path)
    if not p.exists() or p.stat().st_size == 0:
        return []
    with p.open("r", encoding="utf-8") as f:
        data = json.load(f)
    return [Finding.from_dict(item) for item in data]

def save_findings(findings: list[Finding], path: str | Path) -> None:
    p = Path(path)
    p.parent.mkdir(parents=True, exist_ok=True)
    with p.open("w", encoding="utf-8") as f:
        json.dump([f.to_dict() for f in findings], f, indent=2)

def apply_suppressions(
    findings: list[Finding],
    suppressions_path: str | Path,
    now: datetime.date | None = None,
) -> tuple[list[Finding], list[Finding]]:
    if now is None:
        now = datetime.date.today()

    p = Path(suppressions_path)
    if not p.exists():
        return findings, []

    import yaml

    with p.open("r", encoding="utf-8") as f:
        config = yaml.safe_load(f) or {}

    raw_suppressions = config.get("suppressions") or []
    suppression_rules = []
    expired_findings = []

    for s in raw_suppressions:
        tool = s.get("tool")
        rule_id = s.get("rule_id")
        reason = s.get("reason", "")
        expires_str = s.get("expires")
        loc_pattern = s.get("location")

        if not reason or not expires_str:
            raise ValueError(f"Suppression {s} missing mandatory reason or expires field.")

        expires_date = datetime.date.fromisoformat(str(expires_str))
        if expires_date < now:
            expired_findings.append(
                Finding(
                    tool="suppressions",
                    rule_id="expired-suppression",
                    severity="high",
                    title=f"Expired suppression for {tool}:{rule_id}",
                    location=str(p),
                    masvs=["MASVS-POLICY"],
                    suppressed=False,
                    reason=f"Expired on {expires_date}. Original reason: {reason}",
                )
            )
        else:
            suppression_rules.append((tool, rule_id, loc_pattern, reason))

    for f in findings:
        for tool, rule_id, loc_pattern, reason in suppression_rules:
            if (tool == "*" or tool == f.tool) and (rule_id == "*" or rule_id == f.rule_id):
                if loc_pattern is None or loc_pattern in f.location:
                    f.suppressed = True
                    f.reason = reason
                    break

    return findings, expired_findings
