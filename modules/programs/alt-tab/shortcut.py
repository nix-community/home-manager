"""Encode AltTab's first shortcut as an importable macOS preference plist."""

import plistlib
import sys


MODIFIERS = {
    "Control": (1 << 18, "⌃"),
    "Option": (1 << 19, "⌥"),
    "Shift": (1 << 17, "⇧"),
    "Command": (1 << 20, "⌘"),
}

# macOS virtual key codes use US ANSI key positions.
ANSI_KEYS = (
    "A S D F H G Z X C V _ B Q W E R Y T 1 2 3 4 6 5 Equal 9 7 Minus "
    "8 0 RightBracket O U LeftBracket I P Return L J Quote K Semicolon "
    "Backslash Comma Slash N M Period Tab Space Grave Backspace _ Escape"
).split()
KEY_CODES = {key: code for code, key in enumerate(ANSI_KEYS) if key != "_"}
KEY_CODES.update(
    zip(
        (f"F{i}" for i in range(1, 21)),
        (
            122,
            120,
            99,
            118,
            96,
            97,
            98,
            100,
            101,
            109,
            103,
            111,
            105,
            107,
            113,
            106,
            64,
            79,
            80,
            90,
        ),
    )
)
KEY_CODES.update(
    Home=115,
    End=119,
    PageUp=116,
    PageDown=121,
    Delete=117,
    Left=123,
    Right=124,
    Down=125,
    Up=126,
)
CHARACTERS = dict(
    Equal="=",
    Minus="-",
    RightBracket="]",
    LeftBracket="[",
    Return="\r",
    Quote="'",
    Semicolon=";",
    Backslash="\\",
    Comma=",",
    Slash="/",
    Period=".",
    Tab="\t",
    Space=" ",
    Grave="`",
    Backspace="\x7f",
    Escape="\x1b",
    Delete="\uf728",
    Home="\uf729",
    End="\uf72b",
    PageUp="\uf72c",
    PageDown="\uf72d",
    Left="\uf702",
    Right="\uf703",
    Down="\uf701",
    Up="\uf700",
)
CHARACTERS.update((f"F{i}", chr(0xF703 + i)) for i in range(1, 21))


def archive(key_code, flags, characters):
    # NSKeyedArchiver's object graph for SRShortcut, matching the fields in
    # ShortcutRecorder's SRShortcut.encodeWithCoder / initWithCoder:
    # https://github.com/lwouis/alt-tab-macos/blob/v11.7.1/vendor/ShortcutRecorder/Sources/ShortcutRecorder/SRShortcut.m
    objects = [
        "$null",
        {
            "$class": plistlib.UID(2),
            "keyCode": plistlib.UID(3),
            "modifierFlags": plistlib.UID(4),
            "characters": plistlib.UID(5 if characters is not None else 0),
            "charactersIgnoringModifiers": plistlib.UID(
                5 if characters is not None else 0
            ),
        },
        {"$classname": "SRShortcut", "$classes": ["SRShortcut", "NSObject"]},
        key_code,
        flags,
    ]
    if characters is not None:
        objects.append(characters)
    return plistlib.dumps(
        {
            "$archiver": "NSKeyedArchiver",
            "$version": 100000,
            "$objects": objects,
            "$top": {"root": plistlib.UID(1)},
        },
        fmt=plistlib.FMT_BINARY,
        sort_keys=False,
    )


def preferences(shortcut):
    *modifiers, key = shortcut.split("+")
    if len(key) == 1:
        key = key.upper()
    if (
        not modifiers
        or len(set(modifiers)) != len(modifiers)
        or any(modifier not in MODIFIERS for modifier in modifiers)
        or key not in KEY_CODES
    ):
        raise ValueError(f"Unsupported AltTab shortcut: {shortcut!r}")

    flags = sum(MODIFIERS[modifier][0] for modifier in modifiers)
    symbols = "".join(
        symbol for name, (_, symbol) in MODIFIERS.items() if name in modifiers
    )
    characters = CHARACTERS.get(key, key.lower())
    return {
        "holdShortcut": {
            "string": symbols,
            "secureData": archive(65535, flags, None),
        },
        "nextWindowShortcut": {
            "string": key,
            "secureData": archive(KEY_CODES[key], 0, characters),
        },
    }


if __name__ == "__main__":
    with open(sys.argv[2], "wb") as stream:
        plistlib.dump(preferences(sys.argv[1]), stream)
