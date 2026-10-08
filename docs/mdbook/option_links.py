#!/usr/bin/env python3
"""Shared helpers for turning option anchors into mdbook links.

Both the manual conversion and the option page rendering refer to options
through `opt-`, `nixos-opt-` and `nix-darwin-opt-` anchors. The options are
split over one page per namespace, and per module for the namespaces in
`DEEP_SPLIT_NAMESPACES`, so an anchor has to be resolved to a page before it
can be linked to.
"""

from __future__ import annotations

import re
from pathlib import Path


OPTION_LINK = re.compile(
    r"\[(?P<label>[^\]]*)\]\(#(?P<anchor>(?:opt|nixos-opt|nix-darwin-opt)-[^)]+)\)"
)
OPTION_HREF = re.compile(r'href="#(?P<anchor>(?:opt|nixos-opt|nix-darwin-opt)-[^"]+)"')
DEEP_SPLIT_NAMESPACES = {"programs", "services"}
ANCHOR_BASES = (
    ("nix-darwin-opt-", "options/nix-darwin"),
    ("nixos-opt-", "options/nixos"),
    ("opt-", "options/home-manager"),
)


def option_label(anchor: str) -> str:
    """Return the option name an anchor refers to."""
    for prefix, _ in ANCHOR_BASES:
        if anchor.startswith(prefix):
            return anchor.removeprefix(prefix)
    return anchor


def option_page_parts(option_name: str) -> list[str]:
    """Return the path segments of the page documenting an option."""
    parts = option_name.split(".")
    namespace = parts[0]
    if namespace in DEEP_SPLIT_NAMESPACES and len(parts) > 1:
        return parts[:2]
    return [namespace]


def option_fragment(option_name: str, page_parts: list[str], anchor: str) -> str:
    """Return the URL fragment addressing an option on its page.

    A `programs.foo` or `services.foo` path names a module rather than an
    option, so its page holds no matching anchor and the fragment is empty,
    which links to the page itself.
    """
    if len(page_parts) > 1 and option_name.split(".") == page_parts:
        return ""
    return f"#{anchor}"


def option_target(anchor: str, current_file: Path, base_depth: int = 0) -> str:
    """Return a link from `current_file` to the option an anchor refers to.

    `base_depth` is the depth of `current_file` below the manual source root.
    """
    for prefix, base in ANCHOR_BASES:
        if anchor.startswith(prefix):
            option = anchor.removeprefix(prefix).replace("<", "_").replace(">", "_")
            anchor = f"{prefix}{option}"
            break
    else:
        raise ValueError(f"not an option anchor: {anchor}")

    page_parts = option_page_parts(option)
    prefix = "../" * (base_depth + len(current_file.parent.parts))
    fragment = option_fragment(option, page_parts, anchor)
    return f"{prefix}{base}/{'/'.join(page_parts)}.md{fragment}"
