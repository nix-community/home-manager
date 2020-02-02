{ config, lib, pkgs, ... }:

with lib;

let

  cfg = config.programs.fzf;

in {
  options.programs.fzf = {
    enable = mkEnableOption "fzf - a command-line fuzzy finder";

    defaultCommand = mkOption {
      type = types.nullOr types.str;
      default = null;
      example = "fd --type f";
      description = ''
        The command that gets executed as the default source for fzf
        when running.
      '';
    };

    defaultOptions = mkOption {
      type = types.listOf types.str;
      default = [ ];
      example = [ "--height 40%" "--border" ];
      description = ''
        Extra command line options given to fzf by default.
      '';
    };

    fileWidgetCommand = mkOption {
      type = types.nullOr types.str;
      default = null;
      example = "fd --type f";
      description = ''
        The command that gets executed as the source for fzf for the
        CTRL-T keybinding.
      '';
    };

    fileWidgetOptions = mkOption {
      type = types.listOf types.str;
      default = [ ];
      example = [ "--preview 'head {}'" ];
      description = ''
        Command line options for the CTRL-T keybinding.
      '';
    };

    changeDirWidgetCommand = mkOption {
      type = types.nullOr types.str;
      default = null;
      example = "fd --type d";
      description = ''
        The command that gets executed as the source for fzf for the
        ALT-C keybinding.
      '';
    };

    changeDirWidgetOptions = mkOption {
      type = types.listOf types.str;
      default = [ ];
      example = [ "--preview 'tree -C {} | head -200'" ];
      description = ''
        Command line options for the ALT-C keybinding.
      '';
    };

    historyWidgetCommand = mkOption {
      type = types.nullOr types.str;
      default = null;
      description = ''
        The command that gets executed as the source for fzf for the
        CTRL-R keybinding.
      '';
    };

    historyWidgetOptions = mkOption {
      type = types.listOf types.str;
      default = [ ];
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

    enableZshIntegration = mkOption {
      default = true;
      type = types.bool;
      description = ''
        Whether to enable Zsh integration.
      '';
    };
  };

  config = mkIf cfg.enable {
    home.packages = [ pkgs.fzf ];

    home.sessionVariables = mapAttrs (n: v: toString v)
      (filterAttrs (n: v: v != [ ] && v != null) {
        FZF_ALT_C_COMMAND = cfg.changeDirWidgetCommand;
        FZF_ALT_C_OPTS = cfg.changeDirWidgetOptions;
        FZF_CTRL_R_COMMAND = cfg.historyWidgetCommand;
        FZF_CTRL_R_OPTS = cfg.historyWidgetOptions;
        FZF_CTRL_T_COMMAND = cfg.fileWidgetCommand;
        FZF_CTRL_T_OPTS = cfg.fileWidgetOptions;
        FZF_DEFAULT_COMMAND = cfg.defaultCommand;
        FZF_DEFAULT_OPTS = cfg.defaultOptions;
      });

    programs.bash.initExtra = mkIf cfg.enableBashIntegration ''
      if [[ :$SHELLOPTS: =~ :(vi|emacs): ]]; then
        . ${pkgs.fzf}/share/fzf/completion.bash
        . ${pkgs.fzf}/share/fzf/key-bindings.bash
      fi
    '';

    programs.zsh.initExtra = mkIf cfg.enableZshIntegration ''
      if [[ $options[zle] = on ]]; then
        . ${pkgs.fzf}/share/fzf/completion.zsh
        . ${pkgs.fzf}/share/fzf/key-bindings.zsh
      fi
    '';
  };
}
