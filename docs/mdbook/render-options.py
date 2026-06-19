#!/usr/bin/env python3
from __future__ import annotations

import json
import re
import subprocess
import sys
from pathlib import Path


OPTION_LINK = re.compile(
    r"\[(?P<label>[^\]]*)\]\(#(?P<anchor>(?:opt|nixos-opt|nix-darwin-opt)-[^)]+)\)"
)
OPTION_HREF = re.compile(r'href="#(?P<anchor>(?:opt|nixos-opt|nix-darwin-opt)-[^"]+)"')
DEEP_SPLIT_NAMESPACES = {"programs", "services"}


def option_label(anchor: str) -> str:
    if anchor.startswith("nix-darwin-opt-"):
        return anchor.removeprefix("nix-darwin-opt-")
    if anchor.startswith("nixos-opt-"):
        return anchor.removeprefix("nixos-opt-")
    return anchor.removeprefix("opt-")


def option_target(anchor: str, current_file: Path) -> str:
    if anchor.startswith("nix-darwin-opt-"):
        option = anchor.removeprefix("nix-darwin-opt-")
        base = "options/nix-darwin"
    elif anchor.startswith("nixos-opt-"):
        option = anchor.removeprefix("nixos-opt-")
        base = "options/nixos"
    else:
        option = anchor.removeprefix("opt-")
        base = "options/home-manager"

    page_parts = option_page_parts(option)
    prefix = "../" * len(current_file.parent.parts)
    return f"{prefix}{base}/{'/'.join(page_parts)}.md#{anchor}"


def rewrite_option_links(text: str, current_file: Path) -> str:
    text = OPTION_LINK.sub(
        lambda match: (
            f"[{match.group('label') or option_label(match.group('anchor'))}]"
            f"({option_target(match.group('anchor'), current_file)})"
        ),
        text,
    )
    return OPTION_HREF.sub(
        lambda match: f'href="{option_target(match.group("anchor"), current_file)}"',
        text,
    )


def namespace_for(option_name: str) -> str:
    return option_name.split(".", 1)[0]


def option_page_parts(option_name: str) -> list[str]:
    parts = option_name.split(".")
    namespace = parts[0]
    if namespace in DEEP_SPLIT_NAMESPACES and len(parts) > 1:
        return parts[:2]
    return [namespace]


def option_group_for(option_name: str) -> str:
    return "/".join(option_page_parts(option_name))


def render_namespace(
    options: dict[str, object],
    destination: Path,
    manpage_urls: Path,
    revision: str,
    anchor_prefix: str,
    current_file: Path,
) -> None:
    destination.parent.mkdir(parents=True, exist_ok=True)
    source = destination.with_suffix(".json")
    source.write_text(json.dumps(options, sort_keys=True), encoding="utf-8")

    subprocess.run(
        [
            "nixos-render-docs",
            "options",
            "commonmark",
            "--manpage-urls",
            str(manpage_urls),
            "--revision",
            revision,
            "--anchor-style",
            "legacy",
            "--anchor-prefix",
            anchor_prefix,
            str(source),
            str(destination),
        ],
        check=True,
    )
    source.unlink()
    destination.write_text(
        rewrite_option_links(destination.read_text(encoding="utf-8"), current_file),
        encoding="utf-8",
    )


def write_doc(
    name: str,
    doc: dict[str, str],
    manpage_urls: Path,
    revision: str,
    output: Path,
) -> None:
    options_json = Path(doc["json"]) / "share/doc/nixos/options.json"
    options = json.loads(options_json.read_text(encoding="utf-8"))

    grouped: dict[str, dict[str, object]] = {}
    for option_name, option in options.items():
        group = option_group_for(option_name)
        grouped.setdefault(group, {})[option_name] = option

    doc_dir = output / "options" / doc["path"]
    doc_dir.mkdir(parents=True, exist_ok=True)

    groups = sorted(grouped)
    namespaces = sorted({group.split("/", 1)[0] for group in groups})
    nested = {
        namespace: sorted(
            group for group in groups if group.startswith(f"{namespace}/")
        )
        for namespace in namespaces
    }
    index = [
        f"# {doc['title']}\n",
        "\n",
        "Generated from Home Manager option definitions.\n",
        "\n",
        "## Namespaces\n",
        "\n",
    ]
    for namespace in namespaces:
        if nested[namespace]:
            index.append(f"- [{namespace}]({namespace}/index.md)\n")
        else:
            index.append(f"- [{namespace}]({namespace}.md)\n")
    (doc_dir / "index.md").write_text("".join(index), encoding="utf-8")

    summary_dir = output / "summary"
    summary_dir.mkdir(parents=True, exist_ok=True)
    summary = [f"  - [{doc['title']}](options/{doc['path']}/index.md)\n"]

    for namespace in namespaces:
        if nested[namespace]:
            namespace_index = doc_dir / namespace / "index.md"
            namespace_index.parent.mkdir(parents=True, exist_ok=True)
            namespace_index.write_text(
                "".join(
                    [
                        f"# {namespace}\n",
                        "\n",
                        "## Modules\n",
                        "\n",
                        *(
                            f"- [{group.split('/', 1)[1]}]({group.split('/', 1)[1]}.md)\n"
                            for group in nested[namespace]
                        ),
                    ]
                ),
                encoding="utf-8",
            )
            summary.append(
                f"    - [{namespace}](options/{doc['path']}/{namespace}/index.md)\n"
            )
            for group in nested[namespace]:
                module_name = group.split("/", 1)[1]
                summary.append(
                    f"      - [{module_name}](options/{doc['path']}/{namespace}/{module_name}.md)\n"
                )
        else:
            summary.append(
                f"    - [{namespace}](options/{doc['path']}/{namespace}.md)\n"
            )

    for group in groups:
        page = doc_dir / f"{group}.md"
        current_file = Path("options") / doc["path"] / f"{group}.md"
        render_namespace(
            grouped[group],
            page,
            manpage_urls,
            revision,
            doc["prefix"],
            current_file,
        )

    (summary_dir / f"{name}.md").write_text("".join(summary), encoding="utf-8")


def main() -> int:
    if len(sys.argv) != 5:
        print(
            "usage: render-options.py OPTION_DOCS MANPAGE_URLS REVISION OUT",
            file=sys.stderr,
        )
        return 1

    option_docs = json.loads(Path(sys.argv[1]).read_text(encoding="utf-8"))
    manpage_urls = Path(sys.argv[2])
    revision = sys.argv[3]
    output = Path(sys.argv[4])

    for name, doc in option_docs.items():
        write_doc(name, doc, manpage_urls, revision, output)

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
