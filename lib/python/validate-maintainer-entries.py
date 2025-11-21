#!/usr/bin/env python3
"""
Validate maintainer entries in modules/lib/maintainers.nix

This script validates that all maintainer entries have required fields
and that the data types are correct.
"""

import json
import subprocess
import sys


def main():
    print("🔍 Validating maintainer entries...")

    result = subprocess.run(['nix', 'eval', '--file', 'modules/lib/maintainers.nix', '--json'],
                           capture_output=True, text=True, check=True)
    maintainers = json.loads(result.stdout)
    errors = []

    for name, data in maintainers.items():
        if 'github' not in data:
            errors.append(f'{name}: Missing required field "github"')
        if 'githubId' not in data:
            errors.append(f'{name}: Missing required field "githubId"')

        if 'githubId' in data:
            github_id = data['githubId']
            if not isinstance(github_id, int):
                errors.append(f'{name}: githubId must be a number, not a string: {github_id} (type: {type(github_id).__name__})')
            elif github_id <= 0:
                errors.append(f'{name}: githubId must be positive: {github_id}')

    if errors:
        print('❌ Validation errors found:')
        for error in errors:
            print(f'  - {error}')
        sys.exit(1)
    else:
        print('✅ All maintainer entries are valid')
        print(f'✅ Validated {len(maintainers)} maintainer entries')


if __name__ == "__main__":
    main()
