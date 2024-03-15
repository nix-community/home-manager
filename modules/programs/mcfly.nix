{ config, lib, pkgs, ... }:

with lib;
let

  cfg = config.programs.mcfly;

  bashIntegration = ''
    eval "$(${getExe pkgs.mcfly} init bash)"
  '' + optionalString cfg.fzf.enable ''
    eval "$(${getExe pkgs.mcfly-fzf} init bash)"
  '';

  fishIntegration = ''
    ${getExe pkgs.mcfly} init fish | source
  '' + optionalString cfg.fzf.enable ''
    ${getExe pkgs.mcfly-fzf} init fish | source
  '';

  zshIntegration = ''
    eval "$(${getExe pkgs.mcfly} init zsh)"
  '' + optionalString cfg.fzf.enable ''
    eval "$(${getExe pkgs.mcfly-fzf} init zsh)"
  '';

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

    interfaceView = mkOption {
      type = types.enum [ "TOP" "BOTTOM" ];
      default = "TOP";
      description = ''
        Interface view to use.
      '';
    };

    fzf.enable = mkEnableOption "McFly fzf integration";

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
      home.packages = [ pkgs.mcfly ] ++ optional cfg.fzf.enable pkgs.mcfly-fzf;

      programs.bash.initExtra = mkIf cfg.enableBashIntegration bashIntegration;

      programs.zsh.initExtra = mkIf cfg.enableZshIntegration zshIntegration;

      programs.fish.shellInit = mkIf cfg.enableFishIntegration fishIntegration;

      home.sessionVariables.MCFLY_KEY_SCHEME = cfg.keyScheme;

      home.sessionVariables.MCFLY_INTERFACE_VIEW = cfg.interfaceView;
    }

    (mkIf cfg.enableLightTheme { home.sessionVariables.MCFLY_LIGHT = "TRUE"; })

    (mkIf (cfg.fuzzySearchFactor > 0) {
      home.sessionVariables.MCFLY_FUZZY = cfg.fuzzySearchFactor;
    })
  ]);
}
