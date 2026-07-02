{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib)
    getExe
    literalExpression
    mkAfter
    mkIf
    mkOption
    mkOrder
    types
    ;

  cfg = config.programs.fzf;

  renderedColors =
    colors: lib.concatStringsSep "," (lib.mapAttrsToList (name: value: "${name}:${value}") colors);

  bashIntegration = ''
    if [[ :$SHELLOPTS: =~ :(vi|emacs): ]]; then
      eval "$(${getExe cfg.package} --bash)"
    fi
  '';

  zshIntegration = ''
    if [[ $options[zle] = on ]]; then
      source <(${getExe cfg.package} --zsh)
    fi
  '';

  fishIntegration = ''
    ${getExe cfg.package} --fish | source
  '';
in
{
  meta.maintainers = with lib.maintainers; [ khaneliman ];

  imports = [
    (lib.mkRemovedOptionModule [
      "programs"
      "fzf"
      "historyWidgetCommand"
    ] "This option is no longer supported by fzf.")
  ];
  options.programs.fzf = {
    enable = lib.mkEnableOption "fzf - a command-line fuzzy finder";

    package = lib.mkPackageOption pkgs "fzf" { };

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
      example = [
        "--height 40%"
        "--border"
      ];
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
      example = [
        "--sort"
        "--exact"
      ];
      description = ''
        Command line options for the CTRL-R keybinding.
      '';
    };

    colors = mkOption {
      type = types.attrsOf types.str;
      default = { };
      example = literalExpression ''
        {
          bg = "#1e1e1e";
          "bg+" = "#1e1e1e";
          fg = "#d4d4d4";
          "fg+" = "#d4d4d4";
        }
      '';
      description = ''
        Color scheme options added to `FZF_DEFAULT_OPTS`. See
        <https://github.com/junegunn/fzf/wiki/Color-schemes>
        for documentation.
      '';
    };

    tmux = {
      enableShellIntegration = lib.mkEnableOption ''
        setting `FZF_TMUX=1` which causes shell integration to use fzf-tmux
      '';

      shellIntegrationOptions = mkOption {
        type = types.listOf types.str;
        default = [ ];
        example = [ "-d 40%" ];
        description = ''
          If {option}`programs.fzf.tmux.enableShellIntegration` is set to `true`,
          shell integration will use these options for fzf-tmux.
          See {command}`fzf-tmux --help` for available options.
        '';
      };
    };

    enableBashIntegration = lib.hm.shell.mkBashIntegrationOption { inherit config; };

    enableFishIntegration = lib.hm.shell.mkFishIntegrationOption { inherit config; };

    enableZshIntegration = lib.hm.shell.mkZshIntegrationOption { inherit config; };

    enableNushellIntegration = lib.hm.shell.mkNushellIntegrationOption { inherit config; };
  };

  config = mkIf cfg.enable {
    assertions = [
      {
        assertion =
          (cfg.enableBashIntegration || cfg.enableFishIntegration || cfg.enableZshIntegration)
          -> lib.versionAtLeast cfg.package.version "0.48.0";
        message = "fzf package version must be 0.48.0 or greater for bash, fish, or zsh integration";
      }
      {
        assertion = cfg.enableNushellIntegration -> lib.versionAtLeast cfg.package.version "0.73.0";
        message = "fzf package version must be 0.73.0 or greater for nushell integration";
      }
    ];

    home.packages = [ cfg.package ];
    home.sessionVariables = lib.mapAttrs (_n: toString) (
      lib.filterAttrs (_n: v: v != [ ] && v != null) {
        FZF_ALT_C_COMMAND = cfg.changeDirWidgetCommand;
        FZF_ALT_C_OPTS = cfg.changeDirWidgetOptions;
        FZF_CTRL_R_OPTS = cfg.historyWidgetOptions;
        FZF_CTRL_T_COMMAND = cfg.fileWidgetCommand;
        FZF_CTRL_T_OPTS = cfg.fileWidgetOptions;
        FZF_DEFAULT_COMMAND = cfg.defaultCommand;
        FZF_DEFAULT_OPTS =
          cfg.defaultOptions ++ lib.optionals (cfg.colors != { }) [ "--color ${renderedColors cfg.colors}" ];
        FZF_TMUX = if cfg.tmux.enableShellIntegration then "1" else null;
        FZF_TMUX_OPTS = cfg.tmux.shellIntegrationOptions;
      }
    );

    # Note, since fzf unconditionally binds C-r we use `mkOrder` to make the
    # initialization show up a bit earlier. This is to make initialization of
    # other history managers, like mcfly or atuin, take precedence.
    programs.bash.initExtra = mkIf cfg.enableBashIntegration (mkOrder 200 bashIntegration);

    # Note, since fzf unconditionally binds C-r we use `mkOrder` to make the
    # initialization show up a bit earlier. This is to make initialization of
    # other history managers, like mcfly or atuin, take precedence.
    # Still needs to be initialized after oh-my-zsh (order 800), otherwise
    # omz will take precedence.
    programs.zsh.initContent = mkIf cfg.enableZshIntegration (mkOrder 910 zshIntegration);

    programs.fish.interactiveShellInit = mkIf cfg.enableFishIntegration (mkOrder 200 fishIntegration);

    # Initialize after other completion integrations, such as carapace.
    # fzf preserves the previous external completer and falls back to it
    # when its own completer does not apply.
    programs.nushell = lib.mkIf cfg.enableNushellIntegration {
      extraConfig = mkAfter ''
        source ${
          pkgs.runCommand "nushell-fzf-integration.nu" { } ''
            ${lib.getExe cfg.package} --nushell > $out
          ''
        }
      '';
    };

  };
}
