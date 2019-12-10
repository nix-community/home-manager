# -*- coding: utf-8 -*-
"""
Manages the home-manager’s `gnome` module’s `customKeybindings` custom keybindings
using the GSettings_ framework.

The list of keybindings is received in JSON format from the standard input. The JSON
should be a list containing objects with three string attributes, `name`, `binding`
and `command`. For example::

  [
    {"name": "Terminal", "binding": "<Super>Return", "command": "gnome-terminal"},
    {"name": "Browser",  "binding": "<Super>b",      "command": "firefox"}
  ]

The home-manager managed keybindings are updated to match the input list. New bindings
are added as needed and old ones are removed.

.. _GSettings: https://lazka.github.io/pgi-docs/#Gio-2.0/classes/Settings.html
"""
import sys
import json
from itertools import zip_longest
from dataclasses import dataclass
from gi.repository import Gio


MEDIA_KEYS_SCHEMA = "org.gnome.settings-daemon.plugins.media-keys"
"""The GSettings schema for the keyboard shortcuts settings.
See: https://help.gnome.org/users/gnome-help/stable/keyboard-shortcuts-set.html#custom"""

CUSTOM_KEYBINDINGS_KEY = "custom-keybindings"
"""The key within `MEDIA_KEYS_SCHEMA` that contains the list of paths to custom key bindings."""

CUSTOM_KEYBINDING_SCHEMA = (
    "org.gnome.settings-daemon.plugins.media-keys.custom-keybinding"
)
"""The GSettings schema for a custom key binding."""

MANAGED_BINDINGS_BASE_PATH = (
    "/org/gnome/settings-daemon/plugins/media-keys/home-manager-managed-keybindings"
)
"""The base path for key bindings managed by this script.
The individual bindings are named `custom0`, `custom1`, etc. as children of this path."""


@dataclass(frozen=True)
class Binding:
    """Represents one binding entry in the input JSON array."""

    name: str
    binding: str
    command: str


if __name__ == "__main__":
    expected_bindings = json.load(sys.stdin, object_hook=lambda b: Binding(**b))

    # Only activate the changes if the required schemas are installed.
    schema_source = Gio.SettingsSchemaSource.get_default()
    if (
        schema_source.lookup(MEDIA_KEYS_SCHEMA, True) is None
        or schema_source.lookup(CUSTOM_KEYBINDING_SCHEMA, True) is None
    ):
        sys.exit(0)

    media_keys = Gio.Settings.new(MEDIA_KEYS_SCHEMA)

    current_custom_binding_paths = media_keys.get_strv(CUSTOM_KEYBINDINGS_KEY)

    # gather the home-manager-managed binding paths
    current_managed_binding_paths = [
        path
        for path in current_custom_binding_paths
        if path.startswith(f"{MANAGED_BINDINGS_BASE_PATH}/")
    ]

    new_custom_binding_paths = current_custom_binding_paths.copy()

    for i, (managed_binding_path, expected_binding) in enumerate(
        zip_longest(current_managed_binding_paths, expected_bindings)
    ):
        if managed_binding_path is None:
            # more expected bindings than existing: going to add a new binding
            managed_binding_path = f"{MANAGED_BINDINGS_BASE_PATH}/custom{i}/"
            new_custom_binding_paths.append(managed_binding_path)

        managed_binding = Gio.Settings.new_with_path(
            CUSTOM_KEYBINDING_SCHEMA, managed_binding_path
        )
        managed_binding.delay()

        if expected_binding is None:
            # more existing bindings than expected: remove this one
            managed_binding.reset("name")
            managed_binding.reset("binding")
            managed_binding.reset("command")
            new_custom_binding_paths.remove(managed_binding_path)
        else:
            managed_binding.set_string("name", expected_binding.name)
            managed_binding.set_string("binding", expected_binding.binding)
            managed_binding.set_string("command", expected_binding.command)

        if managed_binding.get_has_unapplied():
            managed_binding.apply()
            managed_binding.sync()

    if new_custom_binding_paths != current_custom_binding_paths:
        media_keys.set_strv(CUSTOM_KEYBINDINGS_KEY, new_custom_binding_paths)
        media_keys.sync()
