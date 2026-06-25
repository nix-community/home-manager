{ lib }:
let
  modifierMap = {
    primary = "<Primary>";
    shift = "<Shift>";
    alt = "<Alt>";
    super = "<Super>";
  };
in
{
  toShortcutSource =
    shortcuts:
    let
      formatAction =
        name: short:
        let
          modifierString = lib.concatMapStrings (modifier: modifierMap.${modifier}) short.modifiers;
          binding = "${modifierString}${short.key}";
          optionalBinding = lib.optionalString (binding != "") " \"${binding}\"";
        in
        "(action \"${name}\"${optionalBinding})";

      lines = [ "(file-version 1)" ] ++ lib.mapAttrsToList formatAction shortcuts ++ [ "" ];
    in
    lib.concatStringsSep "\n" lines;
}
