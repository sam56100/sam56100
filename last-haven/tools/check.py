#!/usr/bin/env python3
"""LAST HAVEN verification: one command, every automatic check.

Steps (in order):
  1. gdformat --check   code style (gdtoolkit)
  2. gdlint             static lint (gdtoolkit)
  3. godot --import     refresh the class cache / imports
  4. smoke load         every .gd/.tscn/.tres loads and instantiates
  5. unit/physics tests tests/test_*.gd through tests/run_tests.gd
  6. smoke run          the main scene runs 120 frames headless without errors/warnings

Usage:
  python tools/check.py               # everything
  python tools/check.py --no-godot    # only format + lint (no Godot needed)
  python tools/check.py --fix         # let gdformat rewrite files first
  python tools/check.py -k movement   # only test files whose name contains "movement"

The Godot executable is taken from $GODOT_BIN, otherwise `godot` from the PATH.
Passing this script means "automatically verified", NOT "plays well": see docs/SUIVI_PROJET.md.
"""

from __future__ import annotations

import argparse
import os
import re
import shutil
import subprocess
import sys
from pathlib import Path

PROJECT = Path(__file__).resolve().parent.parent
SKIPPED_DIRS = {".godot", "addons", "export", "build", "__pycache__"}
# Godot output lines that mean something is wrong, even when the exit code is 0.
PROBLEM_PATTERN = re.compile(r"SCRIPT ERROR|Parse Error|^ERROR:|^WARNING:|Failed to load|Cannot ")
# Output lines that are known to be harmless in a headless run (add here, with a reason).
IGNORED_PATTERN = re.compile(r"^$")


def gd_files() -> list[str]:
    files = []
    for path in PROJECT.rglob("*.gd"):
        if SKIPPED_DIRS.isdisjoint(path.relative_to(PROJECT).parts):
            files.append(str(path.relative_to(PROJECT)))
    return sorted(files)


def run(cmd: list[str], timeout: int = 120) -> tuple[int, str]:
    try:
        result = subprocess.run(
            cmd,
            cwd=PROJECT,
            capture_output=True,
            text=True,
            encoding="utf-8",
            errors="replace",
            timeout=timeout,
        )
    except FileNotFoundError:
        return 127, f"command not found: {cmd[0]}"
    except subprocess.TimeoutExpired:
        return 124, f"timeout after {timeout}s: {' '.join(cmd)}"
    return result.returncode, (result.stdout or "") + (result.stderr or "")


def problem_lines(output: str) -> list[str]:
    return [
        line
        for line in output.splitlines()
        if PROBLEM_PATTERN.search(line) and not IGNORED_PATTERN.search(line)
    ]


class Report:
    def __init__(self) -> None:
        self.failed: list[str] = []

    def step(self, name: str, ok: bool, details: str = "") -> None:
        print(f"[{'OK' if ok else 'FAIL'}] {name}")
        if not ok:
            self.failed.append(name)
            if details.strip():
                print("\n".join("      " + line for line in details.strip().splitlines()[-40:]))


def find_godot() -> str | None:
    return os.environ.get("GODOT_BIN") or shutil.which("godot")


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawTextHelpFormatter)
    parser.add_argument("--no-godot", action="store_true", help="only format + lint")
    parser.add_argument("--fix", action="store_true", help="run gdformat in write mode first")
    parser.add_argument("-k", dest="keyword", default="", help="only run test files containing this word")
    args = parser.parse_args()

    report = Report()
    files = gd_files()
    print(f"LAST HAVEN check: {len(files)} GDScript files\n")

    if args.fix:
        code, out = run(["gdformat", *files])
        report.step("gdformat (write)", code == 0, out)
    code, out = run(["gdformat", "--check", *files])
    report.step("gdformat --check", code == 0, out)
    code, out = run(["gdlint", *files])
    report.step("gdlint", code == 0, out)

    if not args.no_godot:
        godot = find_godot()
        if godot is None:
            report.step("godot executable found (set GODOT_BIN or add godot to PATH)", False)
        else:
            base = [godot, "--headless", "--path", str(PROJECT)]
            code, out = run(base + ["--import"])
            report.step("godot --import", code == 0, out)

            code, out = run(base + ["-s", "res://tests/smoke_load.gd"])
            bad = problem_lines(out)
            report.step("smoke load (all scripts/scenes/resources)", code == 0 and not bad, out)

            test_cmd = base + ["--fixed-fps", "60", "-s", "res://tests/run_tests.gd"]
            if args.keyword:
                test_cmd += ["--", args.keyword]
            code, out = run(test_cmd, timeout=180)
            bad = problem_lines(out)
            summary = [line for line in out.splitlines() if line.startswith("----")]
            report.step(f"tests {summary[-1] if summary else ''}".strip(), code == 0 and not bad, out)

            code, out = run(base + ["--fixed-fps", "60", "--quit-after", "120"])
            bad = problem_lines(out)
            report.step("smoke run (main scene, 120 frames)", code == 0 and not bad, out)

    print()
    if report.failed:
        print(f"{len(report.failed)} check(s) FAILED: " + "; ".join(report.failed))
        return 1
    print("All automatic checks passed. (Not the same as playtested: see docs/SUIVI_PROJET.md.)")
    return 0


if __name__ == "__main__":
    sys.exit(main())
