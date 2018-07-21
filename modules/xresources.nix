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
        X server resources that should be set.
        If this and all other xresources options are
        <code>null</code>, then this feature is disabled and no
        <filename>~/.Xresources</filename> link is produced.
      '';
    };

    xresources.extraConfig = mkOption {
      type = types.lines;
      default = "";
      example = literalExample ''
        builtins.readFile (
            pkgs.fetchFromGitHub {
                owner = "solarized";
                repo = "xresources";
                rev = "025ceddbddf55f2eb4ab40b05889148aab9699fc";
                sha256 = "0lxv37gmh38y9d3l8nbnsm1mskcv10g3i83j0kac0a2qmypv1k9f";
            } + "/Xresources.dark"
        )
      '';
      description = ''
        Additional X server resources contents.
        If this and all other xresources options are
        <code>null</code>, then this feature is disabled and no
        <filename>~/.Xresources</filename> link is produced.
      '';
    };
  };

  config = mkIf (cfg.properties != null || cfg.extraConfig != "") {
    home.file.".Xresources".text =
      concatStringsSep "\n" ([]
        ++ (optional (cfg.extraConfig != "") cfg.extraConfig)
        ++ (optionals (cfg.properties != null) (mapAttrsToList formatLine cfg.properties))
      ) + "\n";
  };
}
