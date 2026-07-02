{
  config,
  lib,
  options,
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

  shells = [
    "bash"
    "fish"
    "nushell"
    "zsh"
  ];

in
{
  meta.maintainers = with lib.maintainers; [ khaneliman ];

  imports =
    let
      mkRenamedFzfOption =
        oldName: newPath:
        lib.mkRenamedOptionModule [ "programs" "fzf" oldName ] (
          [
            "programs"
            "fzf"
          ]
          ++ newPath
        );
    in
    [
      (mkRenamedFzfOption "fileWidgetCommand" [
        "fileWidget"
        "command"
      ])
      (mkRenamedFzfOption "fileWidgetOptions" [
        "fileWidget"
        "options"
      ])
      (mkRenamedFzfOption "changeDirWidgetCommand" [
        "changeDirWidget"
        "command"
      ])
      (mkRenamedFzfOption "changeDirWidgetOptions" [
        "changeDirWidget"
        "options"
      ])
      (mkRenamedFzfOption "historyWidgetOptions" [
        "historyWidget"
        "options"
      ])
      (mkRenamedFzfOption "historyWidgetCommand" [
        "historyWidget"
        "command"
      ])
    ];

  options.programs.fzf =
    let
      mkWidgetShellOverrides =
        {
          commandExample ? null,
          commandDescription ? null,
          optionsExample,
          ...
        }:
        lib.genAttrs shells (
          _shell:
          lib.optionalAttrs (commandDescription != null) {
            command = mkOption {
              type = types.nullOr types.str;
              default = null;
              example = commandExample;
              description = ''
                Shell-specific override for this widget command.

                If this is `null`, the global command is used.
              '';
            };
          }
          // {
            options = mkOption {
              type = types.nullOr (types.listOf types.str);
              default = null;
              example = optionsExample;
              description = ''
                Shell-specific override for this widget's command line
                options.

                If this is `null`, the global options are used.
              '';
            };
          }
        );

      mkWidgetOption =
        args@{
          commandExample ? null,
          commandDescription ? null,
          optionsExample,
          optionsDescription,
        }:
        lib.optionalAttrs (commandDescription != null) {
          command = mkOption {
            type = types.nullOr types.str;
            default = null;
            example = commandExample;
            description = commandDescription;
          };
        }
        // {
          options = mkOption {
            type = types.listOf types.str;
            default = [ ];
            example = optionsExample;
            description = optionsDescription;
          };
        }
        // mkWidgetShellOverrides args;
    in
    {
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

      fileWidget = mkWidgetOption {
        commandExample = "fd --type f";
        commandDescription = ''
          The command that gets executed as the source for fzf for the
          CTRL-T keybinding.
        '';
        optionsExample = [ "--preview 'head {}'" ];
        optionsDescription = ''
          Command line options for the CTRL-T keybinding.
        '';
      };

      changeDirWidget = mkWidgetOption {
        commandExample = "fd --type d";
        commandDescription = ''
          The command that gets executed as the source for fzf for the
          ALT-C keybinding.
        '';
        optionsExample = [ "--preview 'tree -C {} | head -200'" ];
        optionsDescription = ''
          Command line options for the ALT-C keybinding.
        '';
      };

      historyWidget = mkWidgetOption {
        commandExample = "";
        commandDescription = ''
          The command that gets executed as the source for fzf for the
          CTRL-R keybinding.

          An empty string disables the CTRL-R binding, which is the supported
          way to yield CTRL-R to a history manager such as Atuin or McFly.
          Non-empty custom commands require fzf 0.66.0 or later but are not
          supported by fzf yet and currently print a shell startup warning.
        '';
        optionsExample = [
          "--sort"
          "--exact"
        ];
        optionsDescription = ''
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

  config =
    let
      shellFzfEnvVars =
        shell:
        lib.filterAttrs (_n: v: v != null) {
          FZF_ALT_C_COMMAND = cfg.changeDirWidget.${shell}.command;
          FZF_ALT_C_OPTS = cfg.changeDirWidget.${shell}.options;
          FZF_CTRL_R_COMMAND = cfg.historyWidget.${shell}.command;
          FZF_CTRL_R_OPTS = cfg.historyWidget.${shell}.options;
          FZF_CTRL_T_COMMAND = cfg.fileWidget.${shell}.command;
          FZF_CTRL_T_OPTS = cfg.fileWidget.${shell}.options;
        };

      fzfEnvVars = lib.filterAttrs (_n: v: v != [ ] && v != null) {
        FZF_ALT_C_COMMAND = cfg.changeDirWidget.command;
        FZF_ALT_C_OPTS = cfg.changeDirWidget.options;
        FZF_CTRL_R_COMMAND = cfg.historyWidget.command;
        FZF_CTRL_R_OPTS = cfg.historyWidget.options;
        FZF_CTRL_T_COMMAND = cfg.fileWidget.command;
        FZF_CTRL_T_OPTS = cfg.fileWidget.options;
        FZF_DEFAULT_COMMAND = cfg.defaultCommand;
        FZF_DEFAULT_OPTS =
          cfg.defaultOptions
          ++ lib.optionals (cfg.colors != { }) [
            "--color ${
              lib.concatStringsSep "," (lib.mapAttrsToList (name: value: "${name}:${value}") cfg.colors)
            }"
          ];
        FZF_TMUX = if cfg.tmux.enableShellIntegration then "1" else null;
        FZF_TMUX_OPTS = cfg.tmux.shellIntegrationOptions;
      };

    in
    mkIf cfg.enable {
      warnings =
        let
          shellIntegrationOptions = {
            bash = "enableBashIntegration";
            fish = "enableFishIntegration";
            nushell = "enableNushellIntegration";
            zsh = "enableZshIntegration";
          };

          integrationCtrlRActive =
            shell: programConfig:
            config.programs.${shell}.enable
            && programConfig.enable
            && programConfig.${shellIntegrationOptions.${shell}};

          fzfCtrlRActive =
            shell:
            let
              shellCommand = cfg.historyWidget.${shell}.command;
              effectiveCommand = if shellCommand != null then shellCommand else cfg.historyWidget.command;
            in
            integrationCtrlRActive shell cfg && effectiveCommand != "";

          atuinCtrlRActive =
            shell:
            integrationCtrlRActive shell config.programs.atuin
            && !(builtins.elem "--disable-ctrl-r" config.programs.atuin.flags);

          mcflyCtrlRActive = shell: shell != "nushell" && integrationCtrlRActive shell config.programs.mcfly;

          ctrlRConflictShells = builtins.filter (
            shell: fzfCtrlRActive shell && (atuinCtrlRActive shell || mcflyCtrlRActive shell)
          ) shells;

          showOptionFiles = option: lib.showFiles option.files;

          fzfCtrlRDefinition =
            shell:
            if cfg.historyWidget.${shell}.command != null then
              "`programs.fzf.historyWidget.${shell}.command` defined in ${
                showOptionFiles options.programs.fzf.historyWidget.${shell}.command
              }"
            else if cfg.historyWidget.command != null then
              "`programs.fzf.historyWidget.command` defined in ${showOptionFiles options.programs.fzf.historyWidget.command}"
            else
              "`programs.fzf.enable` defined in ${showOptionFiles options.programs.fzf.enable}";

          atuinCtrlRDefinition =
            if config.programs.atuin.flags != [ ] then
              "`programs.atuin.flags` defined in ${showOptionFiles options.programs.atuin.flags}"
            else
              "`programs.atuin.enable` defined in ${showOptionFiles options.programs.atuin.enable}";

          mcflyCtrlRDefinition = "`programs.mcfly.enable` defined in ${showOptionFiles options.programs.mcfly.enable}";

          ctrlRConflictDefinitions = lib.concatStringsSep "\n" (
            lib.concatMap (
              shell:
              [
                "  ${shell}:"
                "    ${fzfCtrlRDefinition shell}"
              ]
              ++ lib.optionals (atuinCtrlRActive shell) [ "    ${atuinCtrlRDefinition}" ]
              ++ lib.optionals (mcflyCtrlRActive shell) [ "    ${mcflyCtrlRDefinition}" ]
            ) ctrlRConflictShells
          );
        in

        lib.optional (cfg.historyWidget.command != null && lib.versionOlder cfg.package.version "0.66.0") ''
          `programs.fzf.historyWidget.command` defined in ${lib.showFiles options.programs.fzf.historyWidget.command.files} requires fzf 0.66.0 or greater.

          The configured FZF_CTRL_R_COMMAND value will be ignored by older fzf
          versions.
        ''
        ++ lib.optional (ctrlRConflictShells != [ ]) ''
          programs.fzf and a history manager both configure Ctrl-R for ${lib.concatStringsSep ", " ctrlRConflictShells}.

          Definitions:
          ${ctrlRConflictDefinitions}

          The history manager integration is sourced after fzf and owns Ctrl-R.
          Choose which integration should own Ctrl-R.
          To keep the history manager on Ctrl-R, disable fzf's binding:
            programs.fzf.historyWidget.command = "";
          or disable it for one shell:
            programs.fzf.historyWidget.${builtins.head ctrlRConflictShells}.command = "";
          To keep fzf on Ctrl-R with Atuin, disable Atuin's Ctrl-R binding:
            programs.atuin.flags = [ "--disable-ctrl-r" ];
          McFly has no Ctrl-R-only option in Home Manager. Disable McFly's
          shell integration for that shell if fzf should own Ctrl-R.
          To use another key, disable one default Ctrl-R binding and add a
          shell-specific key binding in your shell configuration.
        '';

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
      home.sessionVariables = lib.mapAttrs (_n: toString) fzfEnvVars;

      # Load early so history managers can reclaim Ctrl-R.
      programs.bash.initExtra =
        let
          vars = shellFzfEnvVars "bash";
        in
        mkIf cfg.enableBashIntegration (
          mkOrder 200 (
            ''
              if [[ :$SHELLOPTS: =~ :(vi|emacs): ]]; then
            ''
            + lib.optionalString (vars != { }) "${config.lib.shell.exportAll vars}\n"
            + ''
                eval "$(${getExe cfg.package} --bash)"
              fi
            ''
          )
        );

      # Still needs to be initialized after oh-my-zsh (order 800), otherwise
      # omz will take precedence.
      programs.zsh.initContent =
        let
          vars = shellFzfEnvVars "zsh";
        in
        mkIf cfg.enableZshIntegration (
          mkOrder 910 (
            ''
              if [[ $options[zle] = on ]]; then
            ''
            + lib.optionalString (vars != { }) "${config.lib.shell.exportAll vars}\n"
            + ''
                source <(${getExe cfg.package} --zsh)
              fi
            ''
          )
        );

      programs.fish.interactiveShellInit =
        let
          vars = shellFzfEnvVars "fish";
          exports = lib.concatStringsSep "\n" (
            lib.mapAttrsToList (name: value: "set -gx ${name} ${lib.escapeShellArg (toString value)}") vars
          );
        in
        mkIf cfg.enableFishIntegration (
          mkOrder 200 (
            lib.optionalString (vars != { }) "${exports}\n"
            + ''
              ${getExe cfg.package} --fish | source
            ''
          )
        );

      # Initialize after other completion integrations, such as carapace.
      # fzf preserves the previous external completer and falls back to it
      # when its own completer does not apply.
      programs.nushell = lib.mkIf cfg.enableNushellIntegration {
        environmentVariables = lib.mapAttrs (_n: toString) fzfEnvVars;

        extraConfig =
          let
            vars = shellFzfEnvVars "nushell";
            assignments = lib.concatStringsSep "\n" (
              lib.mapAttrsToList (
                name: value: "$env.${name} = ${lib.hm.nushell.toNushell { } (toString value)}"
              ) vars
            );
          in
          mkAfter (
            lib.optionalString (vars != { }) "${assignments}\n"
            + ''
              source ${
                pkgs.runCommand "nushell-fzf-integration.nu" { } ''
                  ${getExe cfg.package} --nushell > $out
                ''
              }
            ''
          );
      };

    };
}
