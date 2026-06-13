import configparser
import io
import json
import os
import shlex
import shutil
import subprocess
import sys
import tempfile
from collections.abc import MutableMapping

import json5
import tomlkit


ACTION_KEY = "__homeManagerMutableConfig_action"
INI_TOP_LEVEL_SECTION = "__homeManagerMutableConfig_topLevel"


def new_ini_parser():
    parser = configparser.ConfigParser(
        allow_no_value=True,
        delimiters=("=",),
        default_section="__homeManagerMutableConfig_defaults",
        interpolation=None,
        strict=False,
    )
    parser.optionxform = str
    return parser


def parse_ini(raw):
    parser = new_ini_parser()
    parser.read_string(f"[{INI_TOP_LEVEL_SECTION}]\n{raw}")

    data = {}
    for key, value in parser.items(INI_TOP_LEVEL_SECTION, raw=True):
        data[key] = value

    for section in parser.sections():
        if section == INI_TOP_LEVEL_SECTION:
            continue
        data[section] = dict(parser.items(section, raw=True))

    return data


def render_ini_value(value):
    if isinstance(value, bool):
        return "1" if value else "0"
    return str(value)


def dump_ini(data):
    parser = new_ini_parser()
    top_level = [(key, value) for key, value in data.items() if not isinstance(value, MutableMapping)]
    sections = [(key, value) for key, value in data.items() if isinstance(value, MutableMapping)]

    if top_level:
        parser.add_section(INI_TOP_LEVEL_SECTION)
        for key, value in top_level:
            parser.set(INI_TOP_LEVEL_SECTION, key, None if value is None else render_ini_value(value))

    for section_name, items in sections:
        parser.add_section(section_name)
        for key, value in items.items():
            if isinstance(value, MutableMapping):
                raise ValueError(f"INI section [{section_name}] key {key!r} cannot be a nested table")
            parser.set(section_name, key, None if value is None else render_ini_value(value))

    output = io.StringIO()
    parser.write(output, space_around_delimiters=False)
    rendered = output.getvalue()
    if top_level:
        rendered = rendered.split("\n", 1)[1]
    return rendered.rstrip("\n") + "\n"


def parse_content(raw, fmt):
    if raw.strip() == "":
        return {}
    if fmt == "toml":
        return tomlkit.parse(raw)
    if fmt == "json":
        return json5.loads(raw)
    if fmt == "ini":
        return parse_ini(raw)
    raise ValueError(f"unsupported format {fmt}")


def dump_content(data, fmt):
    if fmt == "toml":
        return tomlkit.dumps(data)
    if fmt == "json":
        return json.dumps(data, indent=2) + "\n"
    if fmt == "ini":
        return dump_ini(data)
    raise ValueError(f"unsupported format {fmt}")


def is_sentinel(value, action):
    return isinstance(value, dict) and value.get(ACTION_KEY) == action


def identity_for(item, keys):
    if not isinstance(item, MutableMapping):
        return None
    values = []
    for key in keys:
        values.append(json.dumps(item.get(key), sort_keys=True, separators=(",", ":")))
    return tuple(values)


def merge_by(existing, managed, keys):
    if not isinstance(existing, list):
        return managed

    index = {}
    for pos, item in enumerate(existing):
        identity = identity_for(item, keys)
        if identity is not None and identity not in index:
            index[identity] = pos

    for managed_item in managed:
        identity = identity_for(managed_item, keys)
        if identity is not None and identity in index:
            existing[index[identity]] = merge(existing[index[identity]], managed_item)
        elif managed_item not in existing:
            existing.append(managed_item)

    return existing


def merge(existing, managed):
    if is_sentinel(managed, "union"):
        items = managed["items"]
        if isinstance(existing, list):
            for item in items:
                if item not in existing:
                    existing.append(item)
            return existing
        return items

    if is_sentinel(managed, "mergeBy"):
        return merge_by(existing, managed["items"], managed["keys"])

    if isinstance(existing, MutableMapping) and isinstance(managed, MutableMapping):
        for key, managed_value in managed.items():
            if is_sentinel(managed_value, "remove"):
                existing.pop(key, None)
            elif is_sentinel(managed_value, "union"):
                items = managed_value["items"]
                if key in existing and isinstance(existing[key], list):
                    for item in items:
                        if item not in existing[key]:
                            existing[key].append(item)
                else:
                    existing[key] = items
            elif is_sentinel(managed_value, "mergeBy"):
                items = managed_value["items"]
                keys = managed_value["keys"]
                if key in existing:
                    existing[key] = merge_by(existing[key], items, keys)
                else:
                    existing[key] = items
            elif key in existing:
                existing[key] = merge(existing[key], managed_value)
            else:
                existing[key] = managed_value
        return existing

    return managed


def fail_or_warn(message, fail):
    if fail:
        print(message, file=sys.stderr)
        raise SystemExit(1)
    print(f"warning: {message}", file=sys.stderr)


def remove_backup(path):
    if not os.path.lexists(path):
        return
    if os.path.isdir(path) and not os.path.islink(path):
        raise IsADirectoryError(f"backup path {path} is a directory")
    os.unlink(path)


def backup_existing(path, command_path=None):
    backup_command = os.environ.get("HOME_MANAGER_BACKUP_COMMAND")
    backup_ext = os.environ.get("HOME_MANAGER_BACKUP_EXT")

    if backup_command:
        command = f"{backup_command} {shlex.quote(command_path or path)}"
        try:
            subprocess.run(command, shell=True, check=True)
        except subprocess.CalledProcessError as exc:
            raise SystemExit(exc.returncode) from exc
        return

    if backup_ext:
        backup_path = f"{path}.{backup_ext}"
        if os.path.lexists(backup_path):
            if os.environ.get("HOME_MANAGER_BACKUP_OVERWRITE") is None:
                print(
                    f"existing backup path {backup_path!r} would be clobbered",
                    file=sys.stderr,
                )
                raise SystemExit(1)
            remove_backup(backup_path)
        shutil.copy2(path, backup_path)
        return

    shutil.copy2(path, path + ".bak")


def merge_entry(entry, home_directory):
    target = entry.get("target")
    if target is None:
        path = entry["path"]
        if os.path.isabs(path):
            target = path
        elif home_directory is not None:
            target = os.path.join(home_directory, path)
        else:
            raise ValueError(f"relative path {path!r} requires a home directory")

    fail_on_invalid = entry["fail_on_invalid"]
    on_invalid = entry["on_invalid"]
    fmt = entry["format"]

    os.makedirs(os.path.dirname(target), exist_ok=True)

    orig_mode = None
    raw_existing = None
    if os.path.exists(target):
        try:
            orig_mode = os.stat(target).st_mode
            with open(target, "r", encoding="utf-8") as existing_file:
                raw_existing = existing_file.read()
            existing = parse_content(raw_existing, fmt)
        except Exception as exc:
            message = f"failed to parse {target}: {exc}"
            if fail_on_invalid:
                fail_or_warn(message, True)
                return
            if on_invalid == "initialize":
                print(f"warning: {message}; treating as empty", file=sys.stderr)
                existing = {}
            else:
                fail_or_warn(message, False)
                return
    else:
        existing = {}

    managed = entry["managed"]

    if not isinstance(existing, MutableMapping) and not (
        is_sentinel(managed, "union") or is_sentinel(managed, "mergeBy")
    ):
        fail_or_warn(
            f"top-level value in {target} is not an object/table; got {type(existing).__name__}",
            fail_on_invalid,
        )
        return

    existing = merge(existing, managed)

    try:
        rendered = dump_content(existing, fmt)
    except Exception as exc:
        fail_or_warn(f"failed to serialize {target}: {exc}", True)
        return

    if rendered == raw_existing:
        return

    write_target = os.path.realpath(target) if os.path.islink(target) else target

    if raw_existing is not None:
        backup_existing(target, command_path=write_target)

    target_dir = os.path.dirname(write_target)
    fd, tmp_path = tempfile.mkstemp(prefix="home-manager.", dir=target_dir)
    try:
        with os.fdopen(fd, "w", encoding="utf-8") as tmp_file:
            tmp_file.write(rendered)
            tmp_file.flush()
            os.fsync(tmp_file.fileno())
        if orig_mode is not None:
            os.chmod(tmp_path, orig_mode & 0o7777)
        os.replace(tmp_path, write_target)
    finally:
        if os.path.exists(tmp_path):
            os.unlink(tmp_path)


def main():
    if len(sys.argv) != 3:
        print(f"usage: {sys.argv[0]} manifest.json home-directory", file=sys.stderr)
        raise SystemExit(2)

    with open(sys.argv[1], "r", encoding="utf-8") as manifest_file:
        entries = json.load(manifest_file)
    home_directory = sys.argv[2]

    for entry in entries:
        merge_entry(entry, home_directory)


if __name__ == "__main__":
    main()
