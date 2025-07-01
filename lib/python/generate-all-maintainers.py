#!/usr/bin/env nix-shell
#!nix-shell -i python3 -p python3
"""
Generate all-maintainers.nix combining local and nixpkgs maintainers.

This script analyzes Home Manager modules to find maintainer references
and combines them with local maintainers to create a master list.
"""

import argparse
import json
import re
import subprocess
import sys
from pathlib import Path
from typing import Dict, List, Optional, Set


class MaintainerGenerator:
    """Generates a comprehensive maintainers list from HM and nixpkgs sources."""

    def __init__(self, hm_root: Path):
        self.hm_root = hm_root
        self.modules_dir = hm_root / "modules"
        self.hm_maintainers_file = self.modules_dir / "lib" / "maintainers.nix"
        self.output_file = hm_root / "all-maintainers.nix"

    def find_nix_files(self) -> List[Path]:
        """Find all .nix files in the modules directory."""
        nix_files = list(self.modules_dir.rglob("*.nix"))
        print(f"📁 Found {len(nix_files)} .nix files in modules")
        return nix_files

    def extract_maintainer_lines(self, file_path: Path) -> List[str]:
        """Extract lines containing maintainer references from a file."""
        try:
            with open(file_path, 'r', encoding='utf-8') as f:
                content = f.read()

            lines = []
            for line in content.splitlines():
                if any(pattern in line for pattern in [
                    "meta.maintainers",
                    "lib.maintainers.",
                    "lib.hm.maintainers.",
                    "with lib.maintainers",
                    "with lib.hm.maintainers"
                ]):
                    lines.append(line.strip())
            return lines
        except Exception as e:
            print(f"Warning: Could not read {file_path}: {e}")
            return []

    def parse_maintainer_names(self, lines: List[str]) -> Set[str]:
        """Parse maintainer names from extracted lines."""
        nixpkgs_maintainers = set()

        for line in lines:
            matches = re.findall(r'lib\.maintainers\.([a-zA-Z0-9_-]+)', line)
            nixpkgs_maintainers.update(matches)

            if 'with lib.maintainers' in line:
                bracket_match = re.search(r'\[([^\]]+)\]', line)
                if bracket_match:
                    content = bracket_match.group(1)
                    names = re.findall(r'\b([a-zA-Z0-9_-]+)\b', content)
                    filtered_names = [
                        name for name in names
                        if name not in {'with', 'lib', 'maintainers', 'meta', 'if', 'then', 'else'}
                    ]
                    nixpkgs_maintainers.update(filtered_names)

        return nixpkgs_maintainers

    def extract_all_maintainers(self) -> Dict[str, Set[str]]:
        """Extract all maintainer references from modules."""
        print("🔎 Extracting maintainer references...")

        nix_files = self.find_nix_files()
        all_lines = []
        hm_maintainers_used = set()

        for file_path in nix_files:
            lines = self.extract_maintainer_lines(file_path)
            all_lines.extend(lines)

            for line in lines:
                hm_matches = re.findall(r'lib\.hm\.maintainers\.([a-zA-Z0-9_-]+)', line)
                hm_maintainers_used.update(hm_matches)

        print("📝 Parsing maintainer names...")
        nixpkgs_maintainers = self.parse_maintainer_names(all_lines)

        print(f"👥 Found potential nixpkgs maintainers: {len(nixpkgs_maintainers)}")
        print(f"🏠 Found HM maintainers used: {len(hm_maintainers_used)}")

        return {
            'nixpkgs': nixpkgs_maintainers,
            'hm_used': hm_maintainers_used
        }

    def load_hm_maintainers(self) -> Set[str]:
        """Load Home Manager maintainer names."""
        try:
            with open(self.hm_maintainers_file, 'r') as f:
                content = f.read()
            names = re.findall(r'^\s*"?([a-zA-Z0-9_-]+)"?\s*=', content, re.MULTILINE)
            return set(names)
        except Exception as e:
            print(f"Error loading HM maintainers: {e}")
            return set()

    def fetch_nixpkgs_maintainers(self) -> Optional[Dict]:
        """Fetch nixpkgs maintainers data using nix eval."""
        print("📡 Attempting to fetch nixpkgs maintainer information...")

        try:
            result = subprocess.run([
                'nix', 'eval', '--file', '<nixpkgs>', 'lib.maintainers', '--json'
            ], capture_output=True, text=True, timeout=30)

            if result.returncode == 0:
                print("✅ Successfully fetched nixpkgs maintainers")
                return json.loads(result.stdout)
            else:
                print("⚠️  Could not fetch nixpkgs maintainers - will create placeholders")
                return None
        except (subprocess.TimeoutExpired, subprocess.CalledProcessError, FileNotFoundError) as e:
            print(f"⚠️  Nix command failed: {e}")
            return None

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
        print("📄 Generating all-maintainers.nix...")

        extracted = self.extract_all_maintainers()
        nixpkgs_maintainers = extracted['nixpkgs']
        hm_maintainer_names = self.load_hm_maintainers()
        nixpkgs_only = nixpkgs_maintainers - hm_maintainer_names
        print(f"📦 Nixpkgs-only maintainers after deduplication: {len(nixpkgs_only)}")

        nixpkgs_data = self.fetch_nixpkgs_maintainers() or {}

        with open(self.output_file, 'w') as f:
            f.write('''# Home Manager all maintainers list.
#
# This file combines maintainers from:
# - Home Manager specific maintainers (modules/lib/maintainers.nix)
# - Nixpkgs maintainers referenced in Home Manager modules
#
# This file is automatically generated by lib/python/generate-all-maintainers.py
# DO NOT EDIT MANUALLY
#
# To regenerate: ./lib/python/generate-all-maintainers.py
#
{
''')

            print("🏠 Adding Home Manager maintainers...")
            try:
                with open(self.hm_maintainers_file, 'r') as hm_file:
                    hm_content = hm_file.read()

                start = hm_content.find('{')
                end = hm_content.rfind('}')
                if start != -1 and end != -1:
                    inner_content = hm_content[start+1:end]
                    lines = inner_content.split('\n')
                    in_entry = False
                    for line in lines:
                        stripped = line.strip()
                        if not stripped or stripped.startswith('#') or 'keep-sorted' in stripped:
                            continue

                        if '= {' in line and not in_entry:
                            f.write("  # home-manager\n")
                            f.write(f"{line}\n")
                            in_entry = True
                        elif line.strip() == '};' and in_entry:
                            f.write(f"{line}\n")
                            in_entry = False
                        else:
                            f.write(f"{line}\n")
            except Exception as e:
                print(f"Warning: Could not process HM maintainers file: {e}")

            print("📦 Adding referenced nixpkgs maintainers...")
            for maintainer in sorted(nixpkgs_only):
                if maintainer in nixpkgs_data:
                    entry = self.format_maintainer_entry(maintainer, nixpkgs_data[maintainer], "nixpkgs")
                    f.write(f"{entry}\n")
                else:
                    placeholder = {
                        'name': maintainer,
                        'email': f'{maintainer}@example.com',
                        'github': maintainer,
                        'githubId': 0
                    }
                    entry = self.format_maintainer_entry(maintainer, placeholder, "nixpkgs (placeholder)")
                    f.write(f"{entry}\n")

            f.write('''}
''')

        self.validate_generated_file()
        self.print_statistics()

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

    def print_statistics(self) -> None:
        """Print generation statistics."""
        try:
            with open(self.output_file, 'r') as f:
                content = f.read()

            hm_count = content.count('# home-manager')
            nixpkgs_count = content.count('# nixpkgs')
            total_entries = content.count(' = {')

            print(f"✅ Generated {self.output_file}")
            print("📊 Statistics:")
            print(f"   - Home Manager maintainers: {hm_count}")
            print(f"   - Nixpkgs maintainers: {nixpkgs_count}")
            print(f"   - Total entries: {total_entries}")
            print()
        except Exception as e:
            print(f"Could not generate statistics: {e}")


def main():
    parser = argparse.ArgumentParser(description="Generate Home Manager all-maintainers.nix")
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

    generator = MaintainerGenerator(hm_root)
    if args.output:
        generator.output_file = args.output

    print("🔍 Analyzing Home Manager modules for maintainer references...")

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
