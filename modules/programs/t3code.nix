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

  impureConfigMerger = empty: jqOperation: path: staticSettings: ''
    mkdir -p "$(dirname -- ${lib.escapeShellArg path})"
    if [ ! -e ${lib.escapeShellArg path} ]; then
      echo ${lib.escapeShellArg empty} > ${lib.escapeShellArg path}
    fi
    dynamic="$(${lib.getExe json5} --as-json ${lib.escapeShellArg path})"
    static="$(cat ${lib.escapeShellArg staticSettings})"
    config="$(${lib.getExe pkgs.jq} -n ${lib.escapeShellArg jqOperation} --argjson dynamic "$dynamic" --argjson static "$static")"
    printf '%s\n' "$config" > ${lib.escapeShellArg path}
    unset config
  '';

  userDataDir = "${config.home.homeDirectory}/.t3/userdata";

  serverCfg = cfg.server;

  # t3code's headless server binary. pkgs.t3code's mainProgram is the Electron
  # desktop app (t3code-desktop); the server run as a service is `t3`.
  serverBinName = "t3";

  # Wrap the package so the coding-agent and VCS CLIs the user configures are
  # on PATH for the server's subprocesses (git, gh, claude-code, opencode, ...).
  serverPackage =
    if cfg.package != null && serverCfg.extraPackages != [ ] then
      pkgs.symlinkJoin {
        inherit (cfg.package) meta;
        name = "${lib.getName cfg.package}-wrapped-${lib.getVersion cfg.package}";
        paths = [ cfg.package ];
        preferLocalBuild = true;
        nativeBuildInputs = [ pkgs.makeWrapper ];
        postBuild = ''
          wrapProgram $out/bin/${serverBinName} \
            --suffix PATH : ${lib.makeBinPath serverCfg.extraPackages}
        '';
      }
    else
      cfg.package;

  serverExe = lib.getExe' serverPackage serverBinName;

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
      description = ''
        The t3code package to install.
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
        enableAssistantStreaming = true;
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
        settings = {
          favorites = [
            {
              provider = "codex";
              model = "gpt-5.5";
            }
          ];
          sidebarProjectGroupingMode = "repository";
          timestampFormat = "locale";
        };
      };
      description = ''
        Configuration written to t3code's {file}`client-settings.json`.
      '';
    };

    server = {
      enable = lib.mkEnableOption "the t3code headless server as a user service";

      extraPackages = mkOption {
        type = types.listOf types.package;
        default = [ ];
        example = literalExpression "[ pkgs.git pkgs.gh pkgs.claude-code pkgs.opencode ]";
        description = ''
          Extra packages placed on the server's {env}`PATH` so t3code can shell
          out to the coding-agent and version-control CLIs it drives.
        '';
      };

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
      (mkIf (cfg.mutableUserSettings && cfg.userSettings != { }) {
        t3codeSettingsActivation = lib.hm.dag.entryAfter [ "linkGeneration" ] (
          impureConfigMerger "{}" "$dynamic * $static" "${userDataDir}/settings.json" (
            jsonFormat.generate "t3code-user-settings" cfg.userSettings
          )
        );
      })
      (mkIf (cfg.mutableKeybindings && cfg.keybindings != [ ]) {
        t3codeKeybindingsActivation = lib.hm.dag.entryAfter [ "linkGeneration" ] (
          impureConfigMerger "[]"
            "$dynamic + $static | group_by([.key, .when]) | map(reduce .[] as $item ({}; . * $item))"
            "${userDataDir}/keybindings.json"
            (jsonFormat.generate "t3code-user-keybindings" cfg.keybindings)
        );
      })
      (mkIf (cfg.mutableClientSettings && cfg.clientSettings != { }) {
        t3codeClientSettingsActivation = lib.hm.dag.entryAfter [ "linkGeneration" ] (
          impureConfigMerger "{}" "$dynamic * $static" "${userDataDir}/client-settings.json" (
            jsonFormat.generate "t3code-client-settings" cfg.clientSettings
          )
        );
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
                source ${toString serverCfg.environmentFile}
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
