#!/usr/bin/env python3

import argparse
import configparser
import sys
from pathlib import Path
from typing import TextIO

# Merge package MIME defaults into mimeapps.list, preserving package preference order.


def desktop_file_parser() -> configparser.RawConfigParser:
    parser = configparser.RawConfigParser(
        delimiters=("=",), comment_prefixes=("#",), default_section=""
    )
    # Desktop entry keys are case-sensitive.
    parser.optionxform = str
    return parser


def desktop_files(package: Path) -> list[tuple[Path, str]]:
    assert package.is_dir()
    applications = package / "share/applications"
    return [
        (desktop, desktop.relative_to(applications).as_posix().replace("/", "-"))
        for desktop in sorted(applications.rglob("*.desktop"))
    ]


def desktop_mime_types(desktop: Path) -> list[str]:
    entry = desktop_file_parser()
    with desktop.open(encoding="utf-8-sig") as file:
        entry.read_file(file)
    mimes = entry.get("Desktop Entry", "MimeType", fallback="").split(";")
    return [mime for mime in map(str.strip, mimes) if mime]


def merge(base: TextIO, output: TextIO, packages: list[Path]) -> None:
    associations = desktop_file_parser()
    associations.read_file(base)
    defaults = associations["Default Applications"]

    for package in packages:
        for desktop_path, desktop_id in desktop_files(package):
            for mime in desktop_mime_types(desktop_path):
                existing = defaults.get(mime, "")
                defaults[mime] = existing + (";" if existing else "") + desktop_id

    associations["Default Applications"] = dict(sorted(defaults.items()))
    associations.write(output, space_around_delimiters=False)


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("packages", nargs="+", type=Path)
    args = parser.parse_args()
    merge(sys.stdin, sys.stdout, args.packages)
