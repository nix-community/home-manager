import json
import os
import re
import sys


def merge_recursive(base, override):
    if not isinstance(base, dict) or not isinstance(override, dict):
        return override
    merged = dict(base)
    for key, value in override.items():
        merged[key] = merge_recursive(merged.get(key), value)
    return merged


def sanitize_path_component(value):
    # Keep this equivalent to lib.strings.sanitizeDerivationName.
    value = value.lstrip(".")
    value = re.sub(r"[^A-Za-z0-9+._?=-]+", "-", value)
    value = value[-207:]
    return value or "unknown"


specs_path, config_path, marketplace_path, output_path, cache_root, marketplace_name = (
    sys.argv[1:]
)
with open(specs_path, encoding="utf-8") as stream:
    specs = json.load(stream)
with open(config_path, encoding="utf-8") as stream:
    settings = json.load(stream)
with open(marketplace_path, encoding="utf-8") as stream:
    marketplace = json.load(stream)

plugins_by_placeholder = {plugin["name"]: plugin for plugin in marketplace["plugins"]}
cache_paths = set()
for spec in specs:
    source = spec["source"]
    if not os.path.isdir(source):
        raise SystemExit(f"Codex plugin source '{source}' is not a directory")

    manifest_path = os.path.join(source, ".codex-plugin", "plugin.json")
    if os.path.exists(manifest_path):
        with open(manifest_path, encoding="utf-8") as stream:
            manifest = json.load(stream)
        name = manifest["name"]
        version = manifest.get("version", "0.0.0")
    else:
        name = spec["fallbackName"]
        version = "0.0.0"

    if not isinstance(name, str) or not isinstance(version, str):
        raise SystemExit(
            f"Codex plugin manifest '{manifest_path}' has a non-string name or version"
        )

    path_name = sanitize_path_component(name)
    path_version = sanitize_path_component(version)
    relative_cache_path = os.path.join(path_name, path_version)
    if relative_cache_path in cache_paths:
        raise SystemExit(
            f"Codex plugins resolve to duplicate cache path '{relative_cache_path}'"
        )
    cache_paths.add(relative_cache_path)

    destination = os.path.join(output_path, "cache", relative_cache_path)
    os.makedirs(os.path.dirname(destination), exist_ok=True)
    os.symlink(source, destination, target_is_directory=True)

    placeholder_key = f"{spec['placeholder']}@{marketplace_name}"
    actual_key = f"{name}@{marketplace_name}"
    generated_settings = settings["plugins"].pop(placeholder_key)
    settings["plugins"][actual_key] = merge_recursive(
        settings["plugins"].get(actual_key, {}), generated_settings
    )

    plugin = plugins_by_placeholder[spec["placeholder"]]
    plugin["name"] = name
    plugin["source"]["path"] = (
        f"./{cache_root}/{marketplace_name}/{relative_cache_path}"
    )

with open(os.path.join(output_path, "config.json"), "w", encoding="utf-8") as stream:
    json.dump(settings, stream)
with open(
    os.path.join(output_path, "marketplace.json"), "w", encoding="utf-8"
) as stream:
    json.dump(marketplace, stream, indent=2)
    stream.write("\n")
