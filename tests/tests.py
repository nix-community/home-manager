#!/usr/bin/env python3

import argparse
import subprocess
import sys
from collections.abc import Sequence
from pathlib import Path
from textwrap import dedent

SUCCESS_EMOJI = "✅"
FAILURE_EMOJI = "❌"
INFO_EMOJI = "ℹ️"

class TestRunnerError(Exception):
    """Custom exception for TestRunner errors."""
    pass

def _run_command(
    cmd: Sequence[str],
    *,
    cwd: Path | None = None,
    text_input: str | None = None,
    check: bool = True,
) -> subprocess.CompletedProcess:
    """A wrapper for subprocess.run with consistent error handling."""
    try:
        return subprocess.run(
            cmd,
            capture_output=True,
            text=True,
            input=text_input,
            check=check,
            cwd=cwd,
        )
    except FileNotFoundError as e:
        print(f"{FAILURE_EMOJI} Error: Command '{e.filename}' not found. Is it in your PATH?", file=sys.stderr)
        raise TestRunnerError(f"Command not found: {e.filename}") from e
    except subprocess.CalledProcessError as e:
        print(f"{FAILURE_EMOJI} Error executing command: {' '.join(cmd)}", file=sys.stderr)
        if e.stderr:
            print(f"Nix Error Output:\n{e.stderr.strip()}", file=sys.stderr)
        raise TestRunnerError("Subprocess command failed.") from e

class TestRunner:
    """Manages the discovery and execution of Nix-based tests."""

    def __init__(self, repo_root: Path | None = None):
        self.repo_root = repo_root or Path.cwd()

    def get_current_system(self) -> str:
        """Get the current system architecture using Nix."""
        cmd = ["nix", "eval", "--raw", "--impure", "--expr", "builtins.currentSystem"]
        result = _run_command(cmd)
        return result.stdout.strip()

    def discover_tests(self, integration: bool = False) -> list[str]:
        """Discover available tests using 'nix eval'."""
        system = self.get_current_system()
        test_prefix = "integration-test-" if integration else "test-"
        nix_apply_expr = (
            'pkgs: builtins.concatStringsSep "\\n" '
            f'(builtins.filter (name: builtins.match "{test_prefix}.*" name != null) '
            '(builtins.attrNames pkgs))'
        )

        cmd = [
            "nix", "eval", "--raw", "--reference-lock-file", "flake.lock",
            f"./tests#packages.{system}", "--apply", nix_apply_expr
        ]

        result = _run_command(cmd, cwd=self.repo_root)
        return result.stdout.splitlines()

    def filter_tests(self, tests: list[str], filters: list[str]) -> list[str]:
        """Filter tests based on a list of substrings."""
        if not filters:
            return tests
        return [test for test in tests if any(f in test for f in filters)]

    def interactive_select(self, tests: list[str]) -> list[str]:
        """Allow interactive test selection using fzf."""
        if not tests:
            return []

        fzf_input = "\n".join(tests)
        cmd = ["fzf", "--multi", "--header=Select tests (TAB to select, ENTER to confirm)"]

        try:
            result = _run_command(cmd, text_input=fzf_input)
            return result.stdout.splitlines()
        except TestRunnerError:
            # Can happen if fzf is not found or the user cancels (non-zero exit)
            return []

    def run_tests(self, tests_to_run: list[str], nix_args: list[str]) -> bool:
        """Run the selected tests and report the outcome."""
        if not tests_to_run:
            print(f"{INFO_EMOJI} No tests selected to run.", file=sys.stderr)
            return True

        count = len(tests_to_run)
        print(f"{INFO_EMOJI} Running {count} test(s)...")
        failed_tests = []

        for i, test in enumerate(tests_to_run, 1):
            print(f"\n--- Running test {i}/{count}: {test} ---")
            cmd = [
                "nix", "build", "-L", "--reference-lock-file", "flake.lock",
                f"./tests#{test}", *nix_args
            ]
            try:
                # For this command, we want output to go directly to the terminal
                subprocess.run(cmd, check=True, cwd=self.repo_root)
                print(f"{SUCCESS_EMOJI} Test passed: {test}")
            except subprocess.CalledProcessError:
                failed_tests.append(test)
                print(f"{FAILURE_EMOJI} Test failed: {test}", file=sys.stderr)

        print("\n--- Summary ---")
        if not failed_tests:
            print(f"{SUCCESS_EMOJI} All {count} tests passed!")
            return True
        else:
            print(f"{FAILURE_EMOJI} {len(failed_tests)} of {count} test(s) failed:")
            for test in failed_tests:
                print(f"  - {test}")
            return False

def main() -> None:
    """Main entry point for the test runner script."""
    parser = argparse.ArgumentParser(
        description="A modern test runner for Home Manager.",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog=dedent("""\
            Examples:
              %(prog)s
                Run tests interactively.
              %(prog)s -l
                List all available tests.
              %(prog)s -l alacritty
                List tests matching 'alacritty'.
              %(prog)s alacritty
                Run all tests matching 'alacritty'.
              %(prog)s -i firefox git
                Interactively select from tests matching 'firefox' or 'git'.
              %(prog)s -t
                Run integration tests interactively.
              %(prog)s -- --show-trace
                Pass '--show-trace' to all 'nix build' commands.
        """)
    )
    parser.add_argument(
        '-l', '--list', action='store_true', help='List available tests instead of running them.'
    )
    parser.add_argument(
        '-i', '--interactive', action='store_true', help='Force interactive test selection using fzf.'
    )
    parser.add_argument(
        '-t', '--integration', action='store_true', help='Discover and run integration tests.'
    )
    parser.add_argument(
        'filters', nargs='*', help='Filter tests by name (partial matches work).'
    )
    parser.add_argument(
        'nix_args', nargs=argparse.REMAINDER,
        help="Arguments to pass to 'nix build', must be after '--'."
    )
    args = parser.parse_args()

    # Strip the '--' if it exists
    nix_args = [arg for arg in args.nix_args if arg != '--']

    runner = TestRunner()
    try:
        print(f"{INFO_EMOJI} Discovering tests...", file=sys.stderr)
        all_tests = runner.discover_tests(integration=args.integration)
        if not all_tests:
            print("No tests found for the current configuration.", file=sys.stderr)
            sys.exit(1)

        tests_to_consider = runner.filter_tests(all_tests, args.filters)
        if not tests_to_consider:
            print("No tests match the provided filters.", file=sys.stderr)
            sys.exit(1)

        if args.list:
            print("\n".join(tests_to_consider))
            print(f"\n{INFO_EMOJI} Found {len(tests_to_consider)} matching tests.", file=sys.stderr)
            return

        # Determine which tests to run
        should_be_interactive = args.interactive or not args.filters
        if should_be_interactive:
            tests_to_run = runner.interactive_select(tests_to_consider)
        else:
            tests_to_run = tests_to_consider

        if not runner.run_tests(tests_to_run, nix_args):
            sys.exit(1)

    except TestRunnerError:
        # Error messages are printed by the functions that raise the exception
        sys.exit(1)

if __name__ == "__main__":
    main()
