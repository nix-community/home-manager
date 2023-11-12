{ config, lib, pkgs, ... }:

with lib;
let

  cfg = config.programs.mcfly;

in {
  meta.maintainers = [ ];

  imports = [
    (mkChangedOptionModule # \
      [ "programs" "mcfly" "enableFuzzySearch" ] # \
      [ "programs" "mcfly" "fuzzySearchFactor" ] # \
      (config:
        let
          value =
            getAttrFromPath [ "programs" "mcfly" "enableFuzzySearch" ] config;
        in if value then 2 else 0))
  ];

  options.programs.mcfly = {
    enable = mkEnableOption "mcfly";

    keyScheme = mkOption {
      type = types.enum [ "emacs" "vim" ];
      default = "emacs";
      description = ''
        Key scheme to use.
      '';
    };

    enableLightTheme = mkOption {
      default = false;
      type = types.bool;
      description = ''
        Whether to enable light mode theme.
      '';
    };

    fuzzySearchFactor = mkOption {
      default = 0;
      type = types.ints.unsigned;
      description = ''
        Whether to enable fuzzy searching.
        0 is off; higher numbers weight toward shorter matches.
        Values in the 2-5 range get good results so far.
      '';
    };

    enableBashIntegration = mkOption {
      default = true;
      type = types.bool;
      description = ''
        Whether to enable Bash integration.
      '';
    };

    enableZshIntegration = mkOption {
      default = true;
      type = types.bool;
      description = ''
        Whether to enable Zsh integration.
      '';
    };

    enableFishIntegration = mkOption {
      default = true;
      type = types.bool;
      description = ''
        Whether to enable Fish integration.
      '';
    };
  };

  config = mkIf cfg.enable (mkMerge [
    {
      home.packages = [ pkgs.mcfly ];

      programs.bash.initExtra = mkIf cfg.enableBashIntegration ''
        eval "$(${pkgs.mcfly}/bin/mcfly init bash)"
      '';

      programs.zsh.initExtra = mkIf cfg.enableZshIntegration ''
        eval "$(${pkgs.mcfly}/bin/mcfly init zsh)"
      '';

      programs.fish.shellInit = mkIf cfg.enableFishIntegration ''
        ${pkgs.mcfly}/bin/mcfly init fish | source
      '';

      home.sessionVariables.MCFLY_KEY_SCHEME = cfg.keyScheme;
    }

    (mkIf cfg.enableLightTheme { home.sessionVariables.MCFLY_LIGHT = "TRUE"; })

    (mkIf (cfg.fuzzySearchFactor > 0) {
      home.sessionVariables.MCFLY_FUZZY = cfg.fuzzySearchFactor;
    })
  ]);
}
