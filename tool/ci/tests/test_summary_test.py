from pathlib import Path
import pytest

from tool.ci.test_summary import (
    build_markdown_summary,
    get_golden_failures,
    get_tested_subpackages,
    parse_lcov_coverage,
)


def test_parse_lcov_coverage_valid(tmp_path: Path) -> None:
    lcov_file = tmp_path / "lcov.info"
    lcov_file.write_text(
        "SF:lib/src/foo.dart\n"
        "DA:1,1\n"
        "LF:10\n"
        "LH:8\n"
        "end_of_record\n"
        "SF:lib/src/bar.dart\n"
        "LF:20\n"
        "LH:10\n"
        "end_of_record\n",
        encoding="utf-8",
    )
    res = parse_lcov_coverage(lcov_file)
    assert res is not None
    lh, lf, pct = res
    assert lh == 18
    assert lf == 30
    assert pytest.approx(pct, 0.01) == 60.0


def test_parse_lcov_coverage_missing(tmp_path: Path) -> None:
    res = parse_lcov_coverage(tmp_path / "nonexistent.info")
    assert res is None


def test_parse_lcov_coverage_empty(tmp_path: Path) -> None:
    empty_file = tmp_path / "empty.info"
    empty_file.write_text("", encoding="utf-8")
    res = parse_lcov_coverage(empty_file)
    assert res == (0, 0, 0.0)


def test_get_tested_subpackages(tmp_path: Path) -> None:
    pkgs_dir = tmp_path / "packages"
    (pkgs_dir / "pkg_a" / "test").mkdir(parents=True)
    (pkgs_dir / "pkg_b").mkdir(parents=True)  # no test dir
    (pkgs_dir / "pkg_c" / "test").mkdir(parents=True)

    pkgs = get_tested_subpackages(pkgs_dir)
    assert pkgs == ["pkg_a", "pkg_c"]


def test_get_golden_failures(tmp_path: Path) -> None:
    test_dir = tmp_path / "test"
    fail_dir = test_dir / "goldens" / "failures"
    fail_dir.mkdir(parents=True)
    (fail_dir / "diff_1.png").touch()

    failures = get_golden_failures(test_dir)
    assert len(failures) == 1
    assert failures[0].name == "diff_1.png"


def test_build_markdown_summary(tmp_path: Path) -> None:
    # Setup mock workspace
    lcov_file = tmp_path / "coverage" / "lcov.info"
    lcov_file.parent.mkdir(parents=True)
    lcov_file.write_text("LF:50\nLH:45\n", encoding="utf-8")

    pkgs_dir = tmp_path / "packages"
    (pkgs_dir / "timer_engine" / "test").mkdir(parents=True)

    md = build_markdown_summary(tmp_path)
    assert "## 📊 Code Quality & Test Summary" in md
    assert "`timer_engine`" in md
    assert "**90.0%** (45/50 lines)" in md
    assert "✅ No diffs" in md
