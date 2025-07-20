#!/usr/bin/env python3
"""
Check for duplicate maintainers between home-manager and nixpkgs

This script compares the maintainers in home-manager with those in nixpkgs
to identify duplicates that should be removed from home-manager.
"""

import json
import subprocess
import sys


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

    # Get nixpkgs maintainers
    nixpkgs_result = subprocess.run(['nix', 'eval', 'nixpkgs#lib.maintainers', '--json'],
                                   capture_output=True, text=True, check=True)
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
