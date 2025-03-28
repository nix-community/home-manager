{ config, lib, pkgs, ... }:

with lib;
let cfg = config.programs.zsh.zsh-abbr;
in {
  meta.maintainers = [ hm.maintainers.ilaumjd ];

  options.programs.zsh.zsh-abbr = {
    enable =
      mkEnableOption "zsh-abbr - zsh manager for auto-expanding abbreviations";

    package = mkPackageOption pkgs "zsh-abbr" { };

    abbreviations = mkOption {
      type = types.attrsOf types.str;
      default = { };
      example = {
        l = "less";
        gco = "git checkout";
      };
      description = ''
        An attribute set that maps aliases (the top level attribute names
        in this option) to abbreviations. Abbreviations are expanded with
        the longer phrase after they are entered.
      '';
    };

    globalAbbreviations = mkOption {
      type = types.attrsOf types.str;
      default = { };
      example = {
        G = "| grep";
        L = "| less -R";
      };
      description = ''
        Similar to [](#opt-programs.zsh.zsh-abbr.abbreviations),
        but are expanded anywhere on a line.
      '';
    };
  };

  config = let
    abbreviations =
      mapAttrsToList (k: v: "abbr ${escapeShellArg k}=${escapeShellArg v}")
      cfg.abbreviations;

    globalAbbreviations =
      mapAttrsToList (k: v: "abbr -g ${escapeShellArg k}=${escapeShellArg v}")
      cfg.globalAbbreviations;

    allAbbreviations = abbreviations ++ globalAbbreviations;
  in mkIf cfg.enable {
    programs.zsh.plugins = [{
      name = "zsh-abbr";
      src = cfg.package;
      file = "share/zsh/zsh-abbr/zsh-abbr.plugin.zsh";
    }];

    xdg.configFile = {
      "zsh-abbr/user-abbreviations".text =
        concatStringsSep "\n" allAbbreviations + "\n";
    };
  };
}
