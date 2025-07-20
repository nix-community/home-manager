#!/usr/bin/env python3
"""
Extract maintainers from changed Home Manager module files.

This script extracts the maintainer extraction logic from the tag-maintainers workflow
for easier testing and validation.
"""

import argparse
import json
import logging
import subprocess
import sys
from pathlib import Path


class NixEvalError(Exception):
    """Custom exception for errors during Nix evaluation."""
    pass


def run_nix_eval(nix_file: Path, *args: str) -> str:
    """Run a Nix evaluation expression and return the result as a string."""
    command = [
        "nix-instantiate",
        "--eval",
        "--strict",
        "--json",
        str(nix_file),
        *args,
    ]
    logging.debug(f"Running command: {' '.join(command)}")
    try:
        result = subprocess.run(
            command,
            capture_output=True,
            text=True,
            check=True,
        )
        return result.stdout.strip()
    except FileNotFoundError:
        logging.error("'nix-instantiate' command not found. Is Nix installed and in your PATH?")
        raise NixEvalError("'nix-instantiate' not found")
    except subprocess.CalledProcessError as e:
        logging.error(f"Nix evaluation failed with exit code {e.returncode}")
        logging.error(f"Stderr: {e.stderr.strip()}")
        raise NixEvalError("Nix evaluation failed") from e


def extract_maintainers(changed_files: list[str], pr_author: str) -> list[str]:
    """Extract and filter maintainers from a list of changed module files."""
    if not changed_files:
        logging.info("No module files changed; no maintainers to tag.")
        return []

    logging.info("Finding maintainers for changed files...")
    nix_file = Path(__file__).parent.parent / "nix" / "extract-maintainers.nix"
    changed_files_json = json.dumps(changed_files)

    try:
        result_json = run_nix_eval(nix_file, "--argstr", "changedFilesJson", changed_files_json)
        maintainers = set(json.loads(result_json))
    except NixEvalError:
        # Error is already logged by run_nix_eval
        return []
    except json.JSONDecodeError as e:
        logging.error(f"Error parsing JSON output from Nix: {e}")
        return []

    filtered_maintainers = sorted(list(maintainers - {pr_author}))

    if not filtered_maintainers:
        logging.info("No maintainers found (or only the PR author is a maintainer).")
        return []

    logging.info(f"Found maintainers to notify: {' '.join(filtered_maintainers)}")
    return filtered_maintainers


def main() -> None:
    """Parse arguments and run the maintainer extraction."""
    logging.basicConfig(level=logging.INFO, format="%(message)s", stream=sys.stderr)

    parser = argparse.ArgumentParser(
        description="Extract maintainers from changed Home Manager module files."
    )
    parser.add_argument(
        "--changed-files",
        help="Newline-separated list of changed files",
        default="",
    )
    parser.add_argument(
        "--pr-author",
        required=True,
        help="GitHub username of the PR author",
    )
    args = parser.parse_args()

    changed_files = [f.strip() for f in args.changed_files.splitlines() if f.strip()]

    maintainers = extract_maintainers(changed_files, args.pr_author)

    print(" ".join(maintainers))


if __name__ == "__main__":
    main()
