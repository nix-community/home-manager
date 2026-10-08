#!/usr/bin/env python3
from __future__ import annotations

import sys
from pathlib import Path


def main() -> int:
    if len(sys.argv) != 5:
        print(
            "usage: substitute-summary.py SUMMARY HM_SUMMARY NIXOS_SUMMARY DARWIN_SUMMARY",
            file=sys.stderr,
        )
        return 1

    summary = Path(sys.argv[1])
    replacements = {
        "@HOME_MANAGER_OPTIONS@": Path(sys.argv[2]).read_text(encoding="utf-8"),
        "@NIXOS_OPTIONS@": Path(sys.argv[3]).read_text(encoding="utf-8"),
        "@NIX_DARWIN_OPTIONS@": Path(sys.argv[4]).read_text(encoding="utf-8"),
    }

    text = summary.read_text(encoding="utf-8")
    for needle, replacement in replacements.items():
        text = text.replace(needle, replacement.rstrip())

    summary.write_text(text, encoding="utf-8")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
