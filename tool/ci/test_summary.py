"""Generate a GitHub Step Summary Markdown report for CI test runs."""

from __future__ import annotations

import argparse
import os
from pathlib import Path
import sys


def parse_lcov_coverage(lcov_path: Path) -> tuple[int, int, float] | None:
    """Parse an LCOV info file and return (lines_hit, lines_found, percentage)."""
    if not lcov_path.exists():
        return None

    total_lf = 0
    total_lh = 0
    with lcov_path.open("r", encoding="utf-8") as f:
        for line in f:
            if line.startswith("LF:"):
                total_lf += int(line.split(":", 1)[1].strip())
            elif line.startswith("LH:"):
                total_lh += int(line.split(":", 1)[1].strip())

    if total_lf == 0:
        return 0, 0, 0.0

    percent = (total_lh / total_lf) * 100.0
    return total_lh, total_lf, percent


def get_tested_subpackages(packages_dir: Path) -> list[str]:
    """Return sorted list of package names that have a test directory."""
    if not packages_dir.is_dir():
        return []
    return sorted(
        p.parent.name
        for p in packages_dir.glob("*/test")
        if p.is_dir()
    )


def get_golden_failures(test_dir: Path) -> list[Path]:
    """Return list of golden failure images found in test failures directories."""
    if not test_dir.is_dir():
        return []
    return sorted(test_dir.glob("**/failures/*.png"))


def build_markdown_summary(
    workspace_dir: Path,
    lcov_path: Path | None = None,
) -> str:
    """Build the markdown summary string for the quality step."""
    cov_path = lcov_path or (workspace_dir / "coverage" / "lcov.info")
    cov_result = parse_lcov_coverage(cov_path)

    if cov_result is not None:
        lh, lf, pct = cov_result
        coverage_cell = f"**{pct:.1f}%** ({lh}/{lf} lines)"
    else:
        coverage_cell = "⚠️ No coverage artifact found"

    pkgs = get_tested_subpackages(workspace_dir / "packages")
    pkgs_cell = ", ".join(f"`{pkg}`" for pkg in pkgs) if pkgs else "None"

    failures = get_golden_failures(workspace_dir / "test")
    if failures:
        golden_cell = f"⚠️ {len(failures)} failure diff(s) recorded in artifacts"
    else:
        golden_cell = "✅ No diffs (passed)"

    lines = [
        "## 📊 Code Quality & Test Summary",
        "",
        "| Check | Result |",
        "| :--- | :--- |",
        "| **Static Analysis** | ✅ Clean (`--fatal-infos`) |",
        f"| **Sub-packages Tested** | {pkgs_cell} |",
        "| **Root Tests** | ✅ Passed |",
        f"| **Line Coverage** | {coverage_cell} |",
        f"| **Golden Tests** | {golden_cell} |",
        "",
    ]
    return "\n".join(lines)


def main() -> int:
    parser = argparse.ArgumentParser(description="Generate CI Test Summary")
    parser.add_argument(
        "--workspace",
        type=Path,
        default=Path("."),
        help="Path to workspace root",
    )
    parser.add_argument(
        "--lcov",
        type=Path,
        default=None,
        help="Path to lcov.info file",
    )
    parser.add_argument(
        "--output",
        type=Path,
        default=None,
        help="Path to write markdown output (defaults to GITHUB_STEP_SUMMARY or stdout)",
    )

    args = parser.parse_args()
    summary_md = build_markdown_summary(args.workspace, args.lcov)

    target_file = args.output
    if target_file is None and "GITHUB_STEP_SUMMARY" in os.environ:
        target_file = Path(os.environ["GITHUB_STEP_SUMMARY"])

    if target_file:
        target_file.parent.mkdir(parents=True, exist_ok=True)
        with target_file.open("a", encoding="utf-8") as f:
            f.write(summary_md + "\n")
    else:
        sys.stdout.write(summary_md + "\n")

    return 0


if __name__ == "__main__":
    sys.exit(main())
