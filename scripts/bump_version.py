#!/usr/bin/env python3
"""Bump Clacky's version in project.yml.

The source-of-truth version lives in project.yml's
`settings.base.MARKETING_VERSION` (analogous to package.json `version`).
CURRENT_PROJECT_VERSION is also incremented monotonically so each shipped
build has a unique build number.

Usage: bump_version.py {patch|minor|major}
"""

from __future__ import annotations
import re
import sys
from pathlib import Path

PROJECT_YML = Path(__file__).resolve().parent.parent / "project.yml"


def read_yaml_value(text: str, key: str) -> str | None:
    m = re.search(rf'^\s*{re.escape(key)}:\s*"([^"]+)"\s*$', text, re.MULTILINE)
    return m.group(1) if m else None


def replace_yaml_value(text: str, key: str, value: str) -> str:
    pattern = rf'(^\s*{re.escape(key)}:\s*)"[^"]+"\s*$'
    new = re.sub(pattern, lambda m: f'{m.group(1)}"{value}"', text, count=1, flags=re.MULTILINE)
    if new == text:
        raise SystemExit(f"Could not find {key} in project.yml")
    return new


def bump_semver(version: str, kind: str) -> str:
    parts = version.split(".")
    if len(parts) != 3 or not all(p.isdigit() for p in parts):
        raise SystemExit(f"MARKETING_VERSION must be MAJOR.MINOR.PATCH, got {version!r}")
    major, minor, patch = (int(p) for p in parts)
    if kind == "patch":
        patch += 1
    elif kind == "minor":
        minor += 1
        patch = 0
    elif kind == "major":
        major += 1
        minor = 0
        patch = 0
    else:
        raise SystemExit(f"Unknown bump kind: {kind} (use patch/minor/major)")
    return f"{major}.{minor}.{patch}"


def main() -> int:
    if len(sys.argv) != 2:
        print(__doc__, file=sys.stderr)
        return 2
    kind = sys.argv[1]
    text = PROJECT_YML.read_text()

    current_marketing = read_yaml_value(text, "MARKETING_VERSION") or "0.0.0"
    current_build = read_yaml_value(text, "CURRENT_PROJECT_VERSION") or "0"

    new_marketing = bump_semver(current_marketing, kind)
    new_build = str(int(current_build) + 1)

    text = replace_yaml_value(text, "MARKETING_VERSION", new_marketing)
    text = replace_yaml_value(text, "CURRENT_PROJECT_VERSION", new_build)
    PROJECT_YML.write_text(text)

    print(f"MARKETING_VERSION: {current_marketing} -> {new_marketing}")
    print(f"CURRENT_PROJECT_VERSION: {current_build} -> {new_build}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
