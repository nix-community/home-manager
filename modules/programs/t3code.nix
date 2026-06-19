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
  mutableConfig = config.lib.mutableConfig;

  userDataDir = "${config.home.homeDirectory}/.t3/userdata";
in
{
  meta.maintainers = [
    lib.maintainers.iamanaws
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
  };

  config = mkIf cfg.enable {
    home.packages = mkIf (cfg.package != null) [ cfg.package ];

    home.mutableConfig = mkMerge [
      (mkIf (cfg.mutableUserSettings && cfg.userSettings != { }) {
        "${userDataDir}/settings.json" = {
          data = cfg.userSettings;
          failOnInvalid = true;
        };
      })
      (mkIf (cfg.mutableKeybindings && cfg.keybindings != [ ]) {
        "${userDataDir}/keybindings.json" = {
          data = mutableConfig.mergeBy [
            "key"
            "when"
          ] cfg.keybindings;
          failOnInvalid = true;
        };
      })
      (mkIf (cfg.mutableClientSettings && cfg.clientSettings != { }) {
        "${userDataDir}/client-settings.json" = {
          data = cfg.clientSettings;
          failOnInvalid = true;
        };
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
  };
}
