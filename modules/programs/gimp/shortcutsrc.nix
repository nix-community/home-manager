{ lib }:

let
  gimprc = import ./gimprc.nix { inherit lib; };

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
        in
        if binding == "" then
          "(action ${gimprc.renderScalar name})"
        else
          "(action ${gimprc.renderScalar name} ${gimprc.renderScalar binding})";

      lines = [ "(file-version 1)" ] ++ lib.mapAttrsToList formatAction shortcuts ++ [ "" ];
    in
    lib.concatStringsSep "\n" lines;
}
