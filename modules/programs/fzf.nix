{ config, lib, pkgs, ... }:

with lib;

let

  cfg = config.programs.fzf;

in {
  imports = [
    (mkRemovedOptionModule [ "programs" "fzf" "historyWidgetCommand" ]
      "This option is no longer supported by fzf.")
  ];

  options.programs.fzf = {
    enable = mkEnableOption "fzf - a command-line fuzzy finder";

    package = mkOption {
      type = types.package;
      default = pkgs.fzf;
      defaultText = literalExpression "pkgs.fzf";
      description = "Package providing the <command>fzf</command> tool.";
    };

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

    historyWidgetOptions = mkOption {
      type = types.listOf types.str;
      default = [ ];
      example = [ "--sort" "--exact" ];
      description = ''
        Command line options for the CTRL-R keybinding.
      '';
    };

    tmux = {
      enableShellIntegration = mkEnableOption ''
        setting <literal>FZF_TMUX=1</literal> which causes shell integration to use fzf-tmux
      '';

      shellIntegrationOptions = mkOption {
        type = types.listOf types.str;
        default = [ ];
        example = literalExpression ''[ "-d 40%" ]'';
        description = ''
          If <option>programs.fzf.tmux.enableShellIntegration</option> is set to <literal>true</literal>,
          shell integration will use these options for fzf-tmux.
          See <command>fzf-tmux --help</command> for available options.
        '';
      };
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

  config = mkIf cfg.enable {
    home.packages = [ cfg.package ];

    home.sessionVariables = mapAttrs (n: v: toString v)
      (filterAttrs (n: v: v != [ ] && v != null) {
        FZF_ALT_C_COMMAND = cfg.changeDirWidgetCommand;
        FZF_ALT_C_OPTS = cfg.changeDirWidgetOptions;
        FZF_CTRL_R_OPTS = cfg.historyWidgetOptions;
        FZF_CTRL_T_COMMAND = cfg.fileWidgetCommand;
        FZF_CTRL_T_OPTS = cfg.fileWidgetOptions;
        FZF_DEFAULT_COMMAND = cfg.defaultCommand;
        FZF_DEFAULT_OPTS = cfg.defaultOptions;
        FZF_TMUX = if cfg.tmux.enableShellIntegration then "1" else null;
        FZF_TMUX_OPTS = cfg.tmux.shellIntegrationOptions;
      });

    # Note, since fzf unconditionally binds C-r we use `mkOrder` to make the
    # initialization show up a bit earlier. This is to make initialization of
    # other history managers, like mcfly or atuin, take precedence.
    programs.bash.initExtra = mkIf cfg.enableBashIntegration (mkOrder 200 ''
      if [[ :$SHELLOPTS: =~ :(vi|emacs): ]]; then
        . ${cfg.package}/share/fzf/completion.bash
        . ${cfg.package}/share/fzf/key-bindings.bash
      fi
    '');

    # Note, since fzf unconditionally binds C-r we use `mkOrder` to make the
    # initialization show up a bit earlier. This is to make initialization of
    # other history managers, like mcfly or atuin, take precedence.
    programs.zsh.initExtra = mkIf cfg.enableZshIntegration (mkOrder 200 ''
      if [[ $options[zle] = on ]]; then
        . ${cfg.package}/share/fzf/completion.zsh
        . ${cfg.package}/share/fzf/key-bindings.zsh
      fi
    '');

    programs.fish.shellInit = mkIf cfg.enableFishIntegration ''
      source ${cfg.package}/share/fzf/key-bindings.fish && fzf_key_bindings
    '';
  };
}
