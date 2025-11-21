#!/usr/bin/env python3
"""
Validate maintainers.nix syntax

This script validates that the maintainers.nix file has valid Nix syntax.
"""

import subprocess
import sys


def main():
    print("🔍 Validating maintainers.nix syntax...")

    try:
        subprocess.run(['nix', 'eval', '--file', 'modules/lib/maintainers.nix', '--json'],
                               capture_output=True, text=True, check=True)
        print("✅ Valid Nix syntax")
    except subprocess.CalledProcessError:
        print("❌ Invalid Nix syntax")
        sys.exit(1)


if __name__ == "__main__":
    main()
