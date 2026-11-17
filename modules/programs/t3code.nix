{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib)
    literalExpression
    mkIf
    mkMerge
    mkOption
    types
    ;

  cfg = config.programs.t3code;
  jsonFormat = pkgs.formats.json { };
  json5 = pkgs.python3Packages.toPythonApplication pkgs.python3Packages.json5;

  immutableFiles = {
    settings = !cfg.mutableUserSettings && cfg.userSettings != { };
    keybindings = !cfg.mutableKeybindings && cfg.keybindings != [ ];
    client-settings = !cfg.mutableClientSettings && cfg.clientSettings != { };
  };

  immutableConfigCleanup = lib.concatMapStrings (
    name:
    lib.hm.generators.mkImpureConfigCleanup {
      file = config.home.file.".t3/userdata/${name}.json";
    }
  ) (lib.attrNames (lib.filterAttrs (_: lib.id) immutableFiles));

  userDataDir = "${config.home.homeDirectory}/.t3/userdata";
  themesDir = "${userDataDir}/themes";

  themeFiles = lib.mapAttrs (
    id: theme:
    if builtins.isAttrs theme && !lib.isDerivation theme then
      jsonFormat.generate "t3code-theme-${id}" theme
    else if lib.isDerivation theme then
      theme
    else
      # Copy a source path into the store. The activation has to read the
      # theme from an absolute path, and a path literal is relative. The
      # path is escaped because it may contain spaces.
      pkgs.runCommand "t3code-theme-${id}" { } "cp ${lib.escapeShellArg "${theme}"} $out"
  ) cfg.themes;

  reservedThemeIds = [
    "system"
    "light"
    "dark"
    "t3-chat"
    "grove"
    "ocean"
    "ember"
    "iris"
    "t3-chat-dark"
    "t3-grove"
    "t3-ocean"
    "t3-ember"
    "t3-iris"
    "t3-code"
  ];

  validThemeId =
    id: builtins.match "^[a-z0-9][a-z0-9-]{0,47}$" id != null && !lib.elem id reservedThemeIds;

  serverCfg = cfg.server;

  # t3code's headless server binary. pkgs.t3code's mainProgram is the Electron
  # desktop app (t3code-desktop); the server run as a service is `t3`.
  # The package wraps `t3` with the coding-agent and VCS CLIs it drives.
  serverExe = lib.getExe' cfg.package "t3";

  serverArgs = [
    "serve"
  ]
  ++ serverCfg.extraArgs;
in
{
  meta.maintainers = [
    lib.maintainers.iamanaws
    lib.maintainers.jonocodes
  ];

  options.programs.t3code = {
    enable = lib.mkEnableOption "T3 Code, a minimal web GUI for coding agents";

    package = mkOption {
      type = types.nullOr types.package;
      default = pkgs.t3code or null;
      defaultText = literalExpression "pkgs.t3code";
      example = literalExpression ''
        pkgs.t3code.override {
          enableClaude = true;
          enableOpencode = true;
        }
      '';
      description = ''
        The t3code package to install.

        The package puts {command}`git`, {command}`gh` and {command}`codex` on
        t3code's {env}`PATH` by default. Override it to enable other CLIs,
        such as Claude Code or OpenCode, for both the desktop app and the
        server.
      '';
    };

    mutableUserSettings = mkOption {
      type = types.bool;
      default = true;
      example = false;
      description = ''
        Whether user settings ({file}`settings.json`) can be updated by t3code.
      '';
    };

    mutableKeybindings = mkOption {
      type = types.bool;
      default = true;
      example = false;
      description = ''
        Whether user keybindings ({file}`keybindings.json`) can be updated by t3code.
      '';
    };

    mutableClientSettings = mkOption {
      type = types.bool;
      default = true;
      example = false;
      description = ''
        Whether client settings ({file}`client-settings.json`) can be updated by t3code.
      '';
    };

    userSettings = mkOption {
      inherit (jsonFormat) type;
      default = { };
      example = {
        enableProviderUpdateChecks = false;
        providerInstances = {
          codex = {
            driver = "codex";
            enabled = true;
            config = {
              enabled = true;
              binaryPath = "codex";
              homePath = "";
              shadowHomePath = "";
              customModels = [ ];
            };
          };
        };
      };
      description = ''
        Configuration written to t3code's {file}`settings.json`.
      '';
    };

    keybindings = mkOption {
      inherit (jsonFormat) type;
      default = [ ];
      example = [
        {
          key = "mod+j";
          command = "terminal.toggle";
        }
        {
          key = "mod+d";
          command = "terminal.split";
          when = "terminalFocus";
        }
        {
          key = "mod+d";
          command = "diff.toggle";
          when = "!terminalFocus";
        }
      ];
      description = ''
        Configuration written to t3code's {file}`keybindings.json`.
      '';
    };

    clientSettings = mkOption {
      inherit (jsonFormat) type;
      default = { };
      example = {
        favorites = [
          {
            provider = "codex";
            model = "gpt-5.5";
          }
        ];
        sidebarProjectGroupingMode = "repository";
        timestampFormat = "locale";
      };
      description = ''
        Configuration written to t3code's {file}`client-settings.json`.
      '';
    };

    themes = mkOption {
      type = types.attrsOf (types.either types.path jsonFormat.type);
      default = { };
      example.nightfall = {
        name = "Nightfall";
        appearance = "dark";
        canvas = "#1a1b26";
        accent = "#7aa2f7";
      };
      description = ''
        Environment themes in {file}`~/.t3/userdata/themes`, keyed by theme id.

        Each value is a JSON attribute set or a path to a JSON file. Theme ids
        must contain 1 to 48 lowercase letters, digits or hyphens, start with
        a letter or digit, and must not conflict with T3's built-in themes.

        T3 refuses symlinks, so Home Manager copies each theme into a regular
        file during activation. Unmanaged files are not removed.

        To select a default, set
        {option}`programs.t3code.userSettings.defaultTheme`.
      '';
    };

    server = {
      enable = lib.mkEnableOption "the t3code headless server as a user service";

      extraArgs = mkOption {
        type = types.listOf types.str;
        default = [ ];
        example = [
          "--host"
          "0.0.0.0"
          "--port"
          "3773"
        ];
        description = ''
          Extra arguments passed to {command}`t3 serve`, for example
          `--host` and `--port`. Run {command}`t3 serve --help` for the
          full list.
        '';
      };

      environmentFile = mkOption {
        type = types.nullOr types.path;
        default = null;
        example = "/run/secrets/t3code";
        description = ''
          Path to an environment file (see {manpage}`systemd.exec(5)`) loaded by
          the service. The recommended way to pass secrets without exposing them
          in the Nix store.
        '';
      };
    };
  };

  config = mkIf cfg.enable {
    home.packages = mkIf (cfg.package != null) [ cfg.package ];

    home.activation = mkMerge [
      (mkIf (immutableConfigCleanup != "") {
        t3codeImmutableConfig =
          lib.hm.dag.entryBetween [ "linkGeneration" ] [ "writeBoundary" ]
            immutableConfigCleanup;
      })
      (mkIf (cfg.mutableUserSettings && cfg.userSettings != { }) {
        t3codeSettingsActivation = lib.hm.dag.entryAfter [ "linkGeneration" ] (
          lib.hm.generators.mkImpureConfigMerger {
            inherit pkgs;
            format = "json";
            empty = "{}";
            jqOperation = "$dynamic * $static";
            path = "${userDataDir}/settings.json";
            mode = "600";
            staticSettings = jsonFormat.generate "t3code-user-settings" cfg.userSettings;
            reader = "${lib.getExe json5} --as-json";
          }
        );
      })
      (mkIf (cfg.mutableKeybindings && cfg.keybindings != [ ]) {
        t3codeKeybindingsActivation = lib.hm.dag.entryAfter [ "linkGeneration" ] (
          lib.hm.generators.mkImpureConfigMerger {
            inherit pkgs;
            format = "json";
            empty = "[]";
            jqOperation = "$dynamic + $static | group_by([.key, .when]) | map(reduce .[] as $item ({}; . * $item))";
            path = "${userDataDir}/keybindings.json";
            staticSettings = jsonFormat.generate "t3code-user-keybindings" cfg.keybindings;
            reader = "${lib.getExe json5} --as-json";
          }
        );
      })
      (mkIf (cfg.mutableClientSettings && cfg.clientSettings != { }) {
        t3codeClientSettingsActivation = lib.hm.dag.entryAfter [ "linkGeneration" ] (
          lib.hm.generators.mkImpureConfigMerger {
            inherit pkgs;
            format = "json";
            empty = "{}";
            jqOperation = "$dynamic * $static";
            path = "${userDataDir}/client-settings.json";
            staticSettings = jsonFormat.generate "t3code-client-settings" cfg.clientSettings;
            reader = "${lib.getExe json5} --as-json";
          }
        );
      })
      (mkIf (cfg.themes != { }) {
        t3codeThemes = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
          if [[ ! -v DRY_RUN ]]; then
            ${lib.getExe' pkgs.coreutils "mkdir"} -p ${lib.escapeShellArg themesDir}
          fi
          ${lib.concatStringsSep "\n" (
            lib.mapAttrsToList (
              id: source:
              let
                target = "${themesDir}/${id}.json";
              in
              ''
                if [ -L ${lib.escapeShellArg target} ] || ! ${lib.getExe' pkgs.diffutils "cmp"} -s ${lib.escapeShellArg (toString source)} ${lib.escapeShellArg target}; then
                  if [[ -v DRY_RUN ]]; then
                    echo ${lib.escapeShellArg "Would install T3 Code theme ${target}"}
                  else
                    tmp=$(${lib.getExe' pkgs.coreutils "mktemp"} ${lib.escapeShellArg "${themesDir}/.${id}.XXXXXXXX"})
                    ${lib.getExe' pkgs.coreutils "install"} -m 0644 ${lib.escapeShellArg (toString source)} "$tmp"
                    ${lib.getExe' pkgs.coreutils "mv"} -fT "$tmp" ${lib.escapeShellArg target}
                  fi
                fi
              ''
            ) themeFiles
          )}
        '';
      })
    ];

    home.file = mkMerge [
      (mkIf (!cfg.mutableUserSettings && cfg.userSettings != { }) {
        ".t3/userdata/settings.json".source = jsonFormat.generate "t3code-user-settings" cfg.userSettings;
      })
      (mkIf (!cfg.mutableKeybindings && cfg.keybindings != [ ]) {
        ".t3/userdata/keybindings.json".source =
          jsonFormat.generate "t3code-user-keybindings" cfg.keybindings;
      })
      (mkIf (!cfg.mutableClientSettings && cfg.clientSettings != { }) {
        ".t3/userdata/client-settings.json".source =
          jsonFormat.generate "t3code-client-settings" cfg.clientSettings;
      })
    ];

    assertions = [
      {
        assertion = !serverCfg.enable || cfg.package != null;
        message = "programs.t3code.server.enable requires programs.t3code.package to be set (it is null).";
      }
      {
        assertion = builtins.all validThemeId (lib.attrNames cfg.themes);
        message = "programs.t3code.themes contains an invalid or reserved theme id.";
      }
    ];

    systemd.user.services = mkIf serverCfg.enable {
      t3code = {
        Unit = {
          Description = "t3code headless server";
          Documentation = "https://t3.codes";
          After = [ "network.target" ];
        };

        Service = {
          ExecStart = "${serverExe} ${lib.escapeShellArgs serverArgs}";
          Restart = "on-failure";
          RestartSec = 5;
        }
        // lib.optionalAttrs (serverCfg.environmentFile != null) {
          EnvironmentFile = serverCfg.environmentFile;
        };

        Install = {
          WantedBy = [ "default.target" ];
        };
      };
    };

    launchd.agents = mkIf serverCfg.enable {
      t3code = {
        enable = true;
        config = {
          ProgramArguments =
            let
              launchdWrapper = pkgs.writeShellScriptBin "t3code-launchd-wrapper" ''
                set -a
                source ${lib.escapeShellArg (toString serverCfg.environmentFile)} || exit 1
                set +a
                exec ${serverExe} ${lib.escapeShellArgs serverArgs}
              '';
            in
            if serverCfg.environmentFile == null then
              [ serverExe ] ++ serverArgs
            else
              [ (lib.getExe launchdWrapper) ];
          KeepAlive = {
            Crashed = true;
            SuccessfulExit = false;
          };
          ProcessType = "Background";
          RunAtLoad = true;
        };
      };
    };
  };
}
