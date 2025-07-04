{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib) escapeShellArg mkOption types;
  cfg = config.programs.zsh.zsh-abbr;
in
{
  meta.maintainers = [ lib.maintainers.ilaumjd ];

  options.programs.zsh.zsh-abbr = {
    enable = lib.mkEnableOption "zsh-abbr - zsh manager for auto-expanding abbreviations";

    package = lib.mkPackageOption pkgs "zsh-abbr" { };

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

  config =
    let
      abbreviations = lib.mapAttrsToList (
        k: v: "abbr ${escapeShellArg k}=${escapeShellArg v}"
      ) cfg.abbreviations;

      globalAbbreviations = lib.mapAttrsToList (
        k: v: "abbr -g ${escapeShellArg k}=${escapeShellArg v}"
      ) cfg.globalAbbreviations;

      allAbbreviations = abbreviations ++ globalAbbreviations;
    in
    lib.mkIf cfg.enable {
      programs.zsh.plugins = [
        {
          name = "zsh-abbr";
          src = cfg.package;
          file = "share/zsh/zsh-abbr/zsh-abbr.plugin.zsh";
        }
      ];

      xdg.configFile = {
        "zsh-abbr/user-abbreviations".text = lib.concatStringsSep "\n" allAbbreviations + "\n";
      };
    };
}
