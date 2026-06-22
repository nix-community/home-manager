#!/usr/bin/env python3
from __future__ import annotations

import argparse
import html
import re
import shutil
import sys
from pathlib import Path


SIMPLE_ROLES = (
    "command",
    "component",
    "description",
    "file",
    "index",
    "system",
    "type",
)

HEADING_ANCHOR = re.compile(r"^(#{1,6}\s+)(.*)\s+\{#([^}]+)\}\s*$")
INLINE_ANCHOR = re.compile(r"\[\]\{#([^}]+)\}")
OPTION_ROLE = re.compile(r"(?<![$`])\{option\}`([^`]*)`")
SIMPLE_ROLE = re.compile(r"(?<![$`])\{(" + "|".join(SIMPLE_ROLES) + r")\}`([^`]*)`")
OPTION_LINK = re.compile(
    r"\[(?P<label>[^\]]*)\]\(#(?P<anchor>(?:opt|nixos-opt|nix-darwin-opt)-[^)]+)\)"
)
LEFTOVER_ROLE = re.compile(
    r"(?<![$`])\{(" + "|".join(("option", *SIMPLE_ROLES)) + r")\}`[^`]*`"
)
FENCE = re.compile(r"^\s*(`{3,})(.*)$")
FENCE_CLOSE = re.compile(r"^\s*`{3,}\s*$")
ADMONITION_OPEN = re.compile(r"^\s*:::\s*\{\.(note|warning|example)\}\s*$")
ADMONITION_CLOSE = re.compile(r"^\s*:::\s*$")
DEEP_SPLIT_NAMESPACES = {"programs", "services"}


def option_target(anchor: str, current_file: Path, base_depth: int) -> str:
    if anchor.startswith("nix-darwin-opt-"):
        option = anchor.removeprefix("nix-darwin-opt-")
        option = option.replace("<", "_").replace(">", "_")
        anchor = f"nix-darwin-opt-{option}"
        base = "options/nix-darwin"
    elif anchor.startswith("nixos-opt-"):
        option = anchor.removeprefix("nixos-opt-")
        option = option.replace("<", "_").replace(">", "_")
        anchor = f"nixos-opt-{option}"
        base = "options/nixos"
    else:
        option = anchor.removeprefix("opt-")
        option = option.replace("<", "_").replace(">", "_")
        anchor = f"opt-{option}"
        base = "options/home-manager"

    page_parts = option_page_parts(option)
    prefix = "../" * (base_depth + len(current_file.parent.parts))
    return f"{prefix}{base}/{'/'.join(page_parts)}.md#{anchor}"


def option_page_parts(option_name: str) -> list[str]:
    parts = option_name.split(".")
    namespace = parts[0]
    if namespace in DEEP_SPLIT_NAMESPACES and len(parts) > 1:
        return parts[:2]
    return [namespace]


def option_label(anchor: str) -> str:
    if anchor.startswith("nix-darwin-opt-"):
        return anchor.removeprefix("nix-darwin-opt-")
    if anchor.startswith("nixos-opt-"):
        return anchor.removeprefix("nixos-opt-")
    return anchor.removeprefix("opt-")


def markdown_label(value: str) -> str:
    return value.replace("<", "&lt;").replace(">", "&gt;")


def convert_inline(line: str, current_file: Path, base_depth: int) -> str:
    line = line.replace("index.xhtml", "index.html")
    line = INLINE_ANCHOR.sub(
        lambda match: f'<a id="{html.escape(match.group(1), quote=True)}"></a>',
        line,
    )
    line = OPTION_ROLE.sub(
        lambda match: (
            f"[{markdown_label(match.group(1))}]"
            f"({option_target(f'opt-{match.group(1)}', current_file, base_depth)})"
        ),
        line,
    )
    line = OPTION_LINK.sub(
        lambda match: (
            f"[{markdown_label(match.group('label') or option_label(match.group('anchor')))}]"
            f"({option_target(match.group('anchor'), current_file, base_depth)})"
        ),
        line,
    )
    return SIMPLE_ROLE.sub(lambda match: f"`{match.group(2)}`", line)


def convert_heading(line: str, current_file: Path, base_depth: int) -> str:
    match = HEADING_ANCHOR.match(line)
    if match is None:
        return convert_inline(line, current_file, base_depth)

    prefix, title, anchor = match.groups()
    return (
        f'<a id="{html.escape(anchor, quote=True)}"></a>\n'
        f"{prefix}{convert_inline(title, current_file, base_depth)}"
    )


def is_include_fence(line: str) -> tuple[bool, str]:
    match = FENCE.match(line)
    if match is None:
        return False, ""

    info = match.group(2).strip()
    return info.startswith(("{=include=}", "include")), match.group(1)


def convert_markdown(
    text: str,
    source: Path,
    current_file: Path,
    base_depth: int,
) -> str:
    output: list[str] = []
    in_code_fence = False
    code_fence = ""
    in_include = False
    include_fence = ""
    in_admonition = False

    for raw_line in text.splitlines(keepends=True):
        line = raw_line[:-1] if raw_line.endswith("\n") else raw_line
        newline = "\n" if raw_line.endswith("\n") else ""

        if in_include:
            if FENCE_CLOSE.match(line) and len(line.strip()) >= len(include_fence):
                in_include = False
                include_fence = ""
            continue

        if in_code_fence:
            output.append(raw_line)
            if FENCE_CLOSE.match(line) and len(line.strip()) >= len(code_fence):
                in_code_fence = False
                code_fence = ""
            continue

        include, fence = is_include_fence(line)
        if include:
            in_include = True
            include_fence = fence
            continue

        fence_match = FENCE.match(line)
        if fence_match is not None:
            in_code_fence = True
            code_fence = fence_match.group(1)
            output.append(raw_line)
            continue

        if in_admonition:
            if ADMONITION_CLOSE.match(line):
                in_admonition = False
                continue
            converted = convert_inline(line, current_file, base_depth)
            output.append(f"> {converted}{newline}" if converted else ">\n")
            continue

        admonition = ADMONITION_OPEN.match(line)
        if admonition is not None:
            in_admonition = True
            output.append(f"> **{admonition.group(1).title()}**\n")
            continue

        output.append(convert_heading(line, current_file, base_depth) + newline)

    if in_include:
        raise ValueError(f"{source}: unterminated include block")

    converted = "".join(output)
    if LEFTOVER_ROLE.search(converted):
        raise ValueError(f"{source}: unconverted NixOS-render-docs role remains")
    if "```{=include=}" in converted:
        raise ValueError(f"{source}: unconverted include block remains")

    return converted


def convert_tree(source: Path, destination: Path, base_depth: int) -> None:
    for path in source.rglob("*"):
        if not path.is_file():
            continue

        target = destination / path.relative_to(source)
        target.parent.mkdir(parents=True, exist_ok=True)

        if path.suffix == ".md":
            text = path.read_text(encoding="utf-8")
            target.write_text(
                convert_markdown(text, path, path.relative_to(source), base_depth),
                encoding="utf-8",
            )
        else:
            shutil.copy2(path, target)


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--base-depth", type=int, default=0)
    parser.add_argument("source", type=Path)
    parser.add_argument("destination", type=Path)
    args = parser.parse_args()

    if not args.source.is_dir():
        print(f"missing source directory: {args.source}", file=sys.stderr)
        return 1

    args.destination.mkdir(parents=True, exist_ok=True)
    convert_tree(args.source, args.destination, args.base_depth)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
