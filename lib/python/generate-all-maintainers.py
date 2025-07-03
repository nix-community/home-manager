#!/usr/bin/env nix-shell
#!nix-shell -i python3 -p python3
"""
Generate all-maintainers.nix using meta.maintainers as source of truth.

This script uses the meta.maintainers system to extract maintainer information
by evaluating Home Manager modules, which is much simpler and more
reliable than parsing files with regex.
"""

import argparse
import json
import subprocess
import sys
from pathlib import Path
from typing import Dict


class MetaMaintainerGenerator:
    """Generates maintainers list using meta.maintainers from Home Manager evaluation."""

    def __init__(self, hm_root: Path):
        self.hm_root = hm_root
        self.hm_maintainers_file = hm_root / "modules" / "lib" / "maintainers.nix"
        self.output_file = hm_root / "all-maintainers.nix"
        self.extractor_script = hm_root / "lib" / "nix" / "extract-maintainers-meta.nix"

    def extract_maintainers_from_meta(self) -> Dict:
        """Extract maintainer information using meta.maintainers."""
        print("🔍 Extracting maintainers using meta.maintainers...")

        try:
            result = subprocess.run([
                "nix", "eval", "--impure", "--file", str(self.extractor_script), "--json"
            ], capture_output=True, text=True, timeout=60)

            if result.returncode == 0:
                data = json.loads(result.stdout)
                print("✅ Successfully extracted maintainers using meta.maintainers")
                return data
            else:
                print(f"❌ Failed to extract maintainers: {result.stderr}")
                sys.exit(1)

        except subprocess.TimeoutExpired:
            print("❌ Timeout while extracting maintainers")
            sys.exit(1)
        except Exception as e:
            print(f"❌ Error extracting maintainers: {e}")
            sys.exit(1)

    def format_maintainer_entry(self, name: str, info: Dict, source: str) -> str:
        """Format a single maintainer entry with nix fmt compatible formatting."""
        lines = [f"  # {source}"]
        lines.append(f"  {name} = {{")

        key_order = ["name", "email", "github", "githubId", "matrix", "keys"]
        sorted_keys = sorted(info.keys(), key=lambda k: key_order.index(k) if k in key_order else len(key_order))

        for key in sorted_keys:
            if key.startswith('_'):  # Skip internal fields
                continue

            value = info[key]
            if isinstance(value, str):
                lines.append(f'    {key} = "{value}";')
            elif isinstance(value, int):
                lines.append(f'    {key} = {value};')
            elif isinstance(value, list) and value:
                if all(isinstance(item, dict) for item in value):
                    formatted_items = []
                    for item in value:
                        if isinstance(item, dict):
                            # Handle dict items with proper spacing
                            item_parts = []
                            for k, v in item.items():
                                if isinstance(v, str):
                                    item_parts.append(f'{k} = "{v}"')
                                else:
                                    item_parts.append(f'{k} = {v}')
                            formatted_items.append("{ " + "; ".join(item_parts) + "; }")
                        else:
                            formatted_items.append(f'"{item}"')
                    if len(formatted_items) == 1:
                        lines.append(f'    {key} = [ {formatted_items[0]} ];')
                    else:
                        lines.append(f'    {key} = [')
                        for item in formatted_items:
                            lines.append(f'      {item}')
                        lines.append('    ];')
                else:
                    items = [f'"{item}"' if isinstance(item, str) else str(item) for item in value]
                    if len(items) == 1:
                        lines.append(f'    {key} = [ {items[0]} ];')
                    else:
                        lines.append(f'    {key} = [')
                        for item in items:
                            lines.append(f'      {item}')
                        lines.append('    ];')

        lines.append("  };")
        return "\n".join(lines)

    def generate_maintainers_file(self) -> None:
        """Generate the complete all-maintainers.nix file."""
        print("📄 Generating all-maintainers.nix using meta.maintainers...")

        # Extract maintainers using meta.maintainers
        maintainer_data = self.extract_maintainers_from_meta()

        hm_maintainers = maintainer_data["categorized"]["home-manager"]
        nixpkgs_maintainers = maintainer_data["categorized"]["nixpkgs"]
        formatted_maintainers = maintainer_data["formatted"]

        print(f"🏠 Home Manager maintainers: {len(hm_maintainers)}")
        print(f"📦 Nixpkgs maintainers: {len(nixpkgs_maintainers)}")

        with open(self.output_file, 'w') as f:
            f.write('''# Home Manager all maintainers list.
#
# This file lists all referenced maintainers in Home Manager.
#
# This file is automatically generated using meta.maintainers from Home Manager evaluation
# DO NOT EDIT MANUALLY
#
# To regenerate: ./lib/python/generate-all-maintainers.py
#
{
''')

            # Use the formatted maintainers from Nix evaluation
            print("✨ Adding formatted maintainers using lib.generators.toPretty...")
            f.write(formatted_maintainers)
            f.write("\n")

            f.write('''}
''')

        self.validate_generated_file()
        self.print_statistics(maintainer_data)

    def validate_generated_file(self) -> bool:
        """Validate the generated Nix file syntax."""
        try:
            result = subprocess.run([
                'nix', 'eval', '--file', str(self.output_file), '--json'
            ], capture_output=True, text=True, timeout=10)

            if result.returncode == 0:
                print("✅ Generated file has valid Nix syntax")
                return True
            else:
                print("❌ Warning: Generated file has Nix syntax errors")
                print(result.stderr[:500])
                return False
        except Exception as e:
            print(f"Warning: Could not validate file: {e}")
            return False

    def print_statistics(self, maintainer_data: Dict) -> None:
        """Print generation statistics."""
        stats = maintainer_data["stats"]

        print(f"✅ Generated {self.output_file}")
        print("📊 Statistics:")
        print(f"   - Total files with maintainers: {stats['totalFiles']}")
        print(f"   - Total unique maintainers: {stats['totalMaintainers']}")
        print(f"   - Home Manager maintainers: {stats['hmMaintainers']}")
        print(f"   - Nixpkgs maintainers: {stats['nixpkgsMaintainers']}")
        print()
        print("🎉 Generation completed successfully using meta.maintainers!")


def main():
    parser = argparse.ArgumentParser(
        description="Generate Home Manager all-maintainers.nix using meta.maintainers"
    )
    parser.add_argument(
        '--root',
        type=Path,
        default=None,
        help='Path to Home Manager root (default: auto-detect)'
    )
    parser.add_argument(
        '--output',
        type=Path,
        default=None,
        help='Output file path (default: <root>/all-maintainers.nix)'
    )

    args = parser.parse_args()

    if args.root:
        hm_root = args.root
    else:
        script_dir = Path(__file__).parent
        hm_root = script_dir.parent.parent

    if not (hm_root / "modules" / "lib" / "maintainers.nix").exists():
        print(f"Error: Could not find maintainers.nix in {hm_root}")
        print("Please specify --root or run from Home Manager directory")
        sys.exit(1)

    generator = MetaMaintainerGenerator(hm_root)
    if args.output:
        generator.output_file = args.output

    print("🚀 Generating maintainers using meta.maintainers approach...")

    try:
        generator.generate_maintainers_file()
    except KeyboardInterrupt:
        print("\n❌ Generation cancelled by user")
        sys.exit(1)
    except Exception as e:
        print(f"❌ Error generating maintainers file: {e}")
        sys.exit(1)


if __name__ == "__main__":
    main()
