{ config, lib, pkgs, ... }:

with lib;
let cfg = config.programs.zsh.zsh-abbr;
in {
  meta.maintainers = [ hm.maintainers.ilaumjd ];

  options.programs.zsh.zsh-abbr = {
    enable =
      mkEnableOption "zsh-abbr - zsh manager for auto-expanding abbreviations";

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
  };

  config = mkIf cfg.enable {
    programs.zsh.plugins = [{
      name = "zsh-abbr";
      src = pkgs.zsh-abbr;
      file = "/share/zsh/zsh-abbr/abbr.plugin.zsh";
    }];

    xdg.configFile = {
      "zsh-abbr/user-abbreviations".text = concatStringsSep "\n"
        (mapAttrsToList (k: v: "abbr ${escapeShellArg k}=${escapeShellArg v}")
          cfg.abbreviations) + "\n";
    };
  };
}
