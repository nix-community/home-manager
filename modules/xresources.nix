{ config, lib, pkgs, ... }:

with lib;

let

  cfg = config.xresources;

  formatLine = n: v:
    let
      v' =
        if isBool v then (if v then "true" else "false")
        else toString v;
    in
      "${n}: ${v'}";

in

{
  meta.maintainers = [ maintainers.rycee ];

  options = {
    xresources.properties = mkOption {
      type = types.nullOr types.attrs;
      default = null;
      example = {
        "XTerm*faceName" = "dejavu sans mono";
        "Emacs*toolBar" = 0;
      };
      description = ''
        X server resources that should be set. If <code>null</code>,
        then this feature is disabled and no
        <filename>~/.Xresources</filename> link is produced.
      '';
    };
  };

  config = mkIf (cfg.properties != null) {
    home.file.".Xresources".text =
      concatStringsSep "\n" (
        mapAttrsToList formatLine cfg.properties
      ) + "\n";
  };
}
