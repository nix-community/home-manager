"""Check shortcut archives against ShortcutRecorder's coding contract."""

import plistlib
import sys


with open(sys.argv[1], "rb") as stream:
    preferences = plistlib.load(stream)

assert set(preferences) == {"holdShortcut", "nextWindowShortcut"}
hold_flags = int(sys.argv[2]) if len(sys.argv) > 2 else 1048576
key_code = int(sys.argv[3]) if len(sys.argv) > 3 else 48
key_characters = sys.argv[4] if len(sys.argv) > 4 else "\t"
for name, code, flags, characters in (
    ("holdShortcut", 65535, hold_flags, None),
    ("nextWindowShortcut", key_code, 0, key_characters),
):
    archive = plistlib.loads(preferences[name]["secureData"])
    assert archive["$archiver"] == "NSKeyedArchiver"
    assert archive["$version"] == 100000
    objects = archive["$objects"]
    shortcut = objects[archive["$top"]["root"].data]
    assert objects[shortcut["$class"].data] == {
        "$classname": "SRShortcut",
        "$classes": ["SRShortcut", "NSObject"],
    }
    assert objects[shortcut["keyCode"].data] == code
    assert objects[shortcut["modifierFlags"].data] == flags
    for key in ("characters", "charactersIgnoringModifiers"):
        index = shortcut[key].data
        assert (None if index == 0 else objects[index]) == characters
