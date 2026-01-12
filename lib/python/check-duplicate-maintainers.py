#! /usr/bin/env nix-shell
#! nix-shell -i python3 -p python3
"""
Check for duplicate maintainers between home-manager and nixpkgs

This script compares the maintainers in home-manager with those in nixpkgs
to identify duplicates that should be removed from home-manager.
"""

import json
import subprocess
import sys
from pathlib import Path


def main():
    print("🔍 Checking for duplicate maintainers between HM and nixpkgs...")

    # Get home-manager maintainers
    hm_result = subprocess.run(['nix', 'eval', '--file', 'modules/lib/maintainers.nix', '--json'],
                              capture_output=True, text=True, check=True)
    hm_maintainers = json.loads(hm_result.stdout)
    hm_github_users = set()
    for name, data in hm_maintainers.items():
        if 'github' in data:
            hm_github_users.add(data['github'])

    # Read nixpkgs revision from flake.lock to ensure consistency between local and CI
    flake_lock_path = Path('flake.lock')
    with open(flake_lock_path, 'r') as f:
        flake_lock = json.load(f)
        nixpkgs_rev = flake_lock['nodes']['nixpkgs']['locked']['rev']

    print(f"📌 Using nixpkgs from flake.lock: {nixpkgs_rev[:7]}")

    # Get nixpkgs maintainers from the locked revision
    nixpkgs_result = subprocess.run(
        ['nix', 'eval', f'github:NixOS/nixpkgs/{nixpkgs_rev}#lib.maintainers', '--json'],
        capture_output=True, text=True, check=True
    )
    nixpkgs_maintainers = json.loads(nixpkgs_result.stdout)
    nixpkgs_github_users = set()
    for name, data in nixpkgs_maintainers.items():
        if isinstance(data, dict) and 'github' in data:
            nixpkgs_github_users.add(data['github'])

    # Find duplicates
    duplicates = hm_github_users.intersection(nixpkgs_github_users)

    if duplicates:
        print(f'❌ Found {len(duplicates)} duplicate maintainers between HM and nixpkgs:')
        for github_user in sorted(duplicates):
            # Find the HM attribute name for this github user
            hm_attr = None
            for attr_name, data in hm_maintainers.items():
                if data.get('github') == github_user:
                    hm_attr = attr_name
                    break
            print(f'  - {github_user} (HM attribute: {hm_attr})')
        print()
        print('These maintainers should be removed from HM maintainers file to avoid duplication.')
        print('They can be referenced directly from nixpkgs instead.')
        sys.exit(1)
    else:
        print('✅ No duplicate maintainers found')


if __name__ == "__main__":
    main()
