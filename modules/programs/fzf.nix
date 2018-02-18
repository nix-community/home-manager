{ config, lib, pkgs, ... }:

with lib;

let

  cfg = config.programs.fzf;

in

{
  options.programs.fzf = {
    enable = mkEnableOption "fzf - a command-line fuzzy finder";

    defaultOptions = mkOption {
      type = types.listOf types.str;
      default = [];
      example = [ "--height 40%" "--border" ];
      description = ''
        Extra command line options given to fzf by default.
      '';
    };

    fileWidgetOptions = mkOption {
      type = types.listOf types.str;
      default = [];
      example = [ "--preview 'head {}'" ];
      description = ''
        Command line options for the CTRL-T keybinding.
      '';
    };

    changeDirWidgetOptions = mkOption {
      type = types.listOf types.str;
      default = [];
      example = [ "--preview 'tree -C {} | head -200'" ];
      description = ''
        Command line options for the ALT-C keybinding.
      '';
    };

    historyWidgetOptions = mkOption {
      type = types.listOf types.str;
      default = [];
      example = [ "--sort" "--exact" ];
      description = ''
        Command line options for the CTRL-R keybinding.
      '';
    };

    enableBashIntegration = mkOption {
      default = true;
      type = types.bool;
      description = ''
        Whether to enable Bash integration.
      '';
    };
  };

  config = mkIf cfg.enable {
    home.packages = [ pkgs.fzf ];

    home.sessionVariables =
      mapAttrs (n: v: toString v) (
        filterAttrs (n: v: v != []) {
          FZF_ALT_C_OPTS = cfg.changeDirWidgetOptions;
          FZF_CTRL_R_OPTS = cfg.historyWidgetOptions;
          FZF_CTRL_T_OPTS = cfg.fileWidgetOptions;
          FZF_DEFAULT_OPTS = cfg.defaultOptions;
        }
      );

    programs.bash.initExtra = mkIf cfg.enableBashIntegration ''
      . ${pkgs.fzf}/share/fzf/completion.bash
      . ${pkgs.fzf}/share/fzf/key-bindings.bash
    '';
  };
}
