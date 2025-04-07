{ lib }:
let
  letters =
    let
      alphabet = "ABCDEFGHIJKLMNOPQRSTUVWXYZ";
      lettersList = lib.stringToCharacters alphabet;
      indices = builtins.genList (i: i + 4) 26;
    in
    lib.listToAttrs (
      lib.zipListsWith (letter: index: {
        name = letter;
        value = "0x${lib.toHexString index}";
      }) lettersList indices
    );

  numbers = {
    One = "0x1E";
    Two = "0x1F";
    Three = "0x20";
    Four = "0x21";
    Five = "0x22";
    Six = "0x23";
    Seven = "0x24";
    Eight = "0x25";
    Nine = "0x26";
    Zero = "0x27";
  };

  specialKeys = {
    Enter = "0x28";
    Escape = "0x29";
    Backspace = "0x2A";
    Tab = "0x2B";
    Spacebar = "0x2C";
    Minus = "0x2D";
    Equal = "0x2E";
    SquareBracketOpen = "0x2F";
    SquareBracketClose = "0x30";
    Backslash = "0x31";
    Hash = "0x32";
    Semicolon = "0x33";
    SingleQuote = "0x34";
    GraveAccent = "0x35";
    Comma = "0x36";
    Dot = "0x37";
    Slash = "0x38";
    Capslock = "0x39";
  };

  fKeys1To12 = {
    F1 = "0x3A";
    F2 = "0x3B";
    F3 = "0x3C";
    F4 = "0x3D";
    F5 = "0x3E";
    F6 = "0x3F";
    F7 = "0x40";
    F8 = "0x41";
    F9 = "0x42";
    F10 = "0x43";
    F11 = "0x44";
    F12 = "0x45";
  };

  fKeys13To24 = {
    F13 = "0x68";
    F14 = "0x69";
    F15 = "0x6A";
    F16 = "0x6B";
    F17 = "0x6C";
    F18 = "0x6D";
    F19 = "0x6E";
    F20 = "0x6F";
    F21 = "0x70";
    F22 = "0x71";
    F23 = "0x72";
    F24 = "0x73";
  };

  navigationKeys = {
    PrintScreen = "0x46";
    ScrollLock = "0x47";
    Pause = "0x48";
    Insert = "0x49";
    Home = "0x4A";
    PageUp = "0x4B";
    ForwardDelete = "0x4C";
    End = "0x4D";
    PageDown = "0x4E";
    RightArrow = "0x4F";
    LeftArrow = "0x50";
    DownArrow = "0x51";
    UpArrow = "0x52";
    NumLock = "0x53";
  };

  modifierKeys = {
    Control = "0xE0";
    Shift = "0xE1";
    Option = "0xE2";
    Command = "0xE3";
    RightControl = "0xE4";
    RightShift = "0xE5";
    RightOption = "0xE6";
    RightCommand = "0xE7";
  };

  keypadKeys = {
    Slash = "0x54";
    Asterisk = "0x55";
    Minus = "0x56";
    Plus = "0x57";
    Enter = "0x58";
    One = "0x59";
    Two = "0x5A";
    Three = "0x5B";
    Four = "0x5C";
    Five = "0x5D";
    Six = "0x5E";
    Seven = "0x5F";
    Eight = "0x60";
    Nine = "0x61";
    Zero = "0x62";
    Dot = "0x63";
    BashSlash = "0x64";
    Application = "0x65";
    Power = "0x66";
    Equal = "0x67";
  };

  mapToInt =
    keyPage: attrs:
    lib.mapAttrs (
      name: value:
      let
        keycode = lib.fromHexString (lib.removePrefix "0x" value);
      in
      "0x${lib.toHexString (keyPage + keycode)}"
    ) attrs;

  page7Keys = mapToInt (lib.fromHexString "700000000") (
    letters // numbers // specialKeys // fKeys1To12 // fKeys13To24 // navigationKeys // modifierKeys
  );
  pageFFKeys = mapToInt (lib.fromHexString "FF00000000") { Fn = "0x3"; };
in
{
  keyboard = page7Keys // pageFFKeys;
  keypad = mapToInt keypadKeys;
}
