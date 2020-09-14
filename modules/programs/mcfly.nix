{ config, lib, pkgs, ... }:

with lib;
let

  cfg = config.programs.mcfly;

in {
  meta.maintainers = [ maintainers.marsam ];

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
        source "${pkgs.mcfly}/share/mcfly/mcfly.bash"
      '';

      programs.zsh.initExtra = mkIf cfg.enableZshIntegration ''
        source "${pkgs.mcfly}/share/mcfly/mcfly.zsh"
      '';

      programs.fish.shellInit = mkIf cfg.enableFishIntegration ''
        source "${pkgs.mcfly}/share/mcfly/mcfly.fish"
        if status is-interactive
          mcfly_key_bindings
        end
      '';

      home.sessionVariables.MCFLY_KEY_SCHEME = cfg.keyScheme;
    }

    (mkIf cfg.enableLightTheme { home.sessionVariables.MCFLY_LIGHT = "TRUE"; })
  ]);
}
