{ config, lib, pkgs, ... }:

with lib;

let

  cfg = config.programs.vscode;

  vscodePname = cfg.package.pname;

  jsonFormat = pkgs.formats.json { };

  configDir = {
    "vscode" = "Code";
    "vscode-insiders" = "Code - Insiders";
    "vscodium" = "VSCodium";
  }.${vscodePname};

  extensionDir = {
    "vscode" = "vscode";
    "vscode-insiders" = "vscode-insiders";
    "vscodium" = "vscode-oss";
  }.${vscodePname};

  userDir = if pkgs.stdenv.hostPlatform.isDarwin then
    "Library/Application Support/${configDir}/User"
  else
    "${config.xdg.configHome}/${configDir}/User";

  configFilePath = "${userDir}/settings.json";
  tasksFilePath = "${userDir}/tasks.json";
  keybindingsFilePath = "${userDir}/keybindings.json";

  # TODO: On Darwin where are the extensions?
  extensionPath = ".${extensionDir}/extensions";

in {
  imports = [
    (mkChangedOptionModule [ "programs" "vscode" "immutableExtensionsDir" ] [
      "programs"
      "vscode"
      "mutableExtensionsDir"
    ] (config: !config.programs.vscode.immutableExtensionsDir))
  ];

  options = {
    programs.vscode = {
      enable = mkEnableOption "Visual Studio Code";

      package = mkOption {
        type = types.package;
        default = pkgs.vscode;
        example = literalExpression "pkgs.vscodium";
        description = ''
          Version of Visual Studio Code to install.
        '';
      };

      userSettings = mkOption {
        type = jsonFormat.type;
        default = { };
        example = literalExpression ''
          {
            "update.channel" = "none";
            "[nix]"."editor.tabSize" = 2;
          }
        '';
        description = ''
          Configuration written to Visual Studio Code's
          <filename>settings.json</filename>.
        '';
      };

      userTasks = mkOption {
        type = jsonFormat.type;
        default = { };
        example = literalExpression ''
          {
            "version": "2.0.0",
            "tasks": [
              {
                "type": "shell",
                "label": "Hello task",
                "command": "hello",
              }
            ]
          }
        '';
        description = ''
          Configuration written to Visual Studio Code's
          <filename>tasks.json</filename>.
        '';
      };

      keybindings = mkOption {
        type = types.listOf (types.submodule {
          options = {
            key = mkOption {
              type = types.str;
              example = "ctrl+c";
              description = "The key or key-combination to bind.";
            };

            command = mkOption {
              type = types.str;
              example = "editor.action.clipboardCopyAction";
              description = "The VS Code command to execute.";
            };

            when = mkOption {
              type = types.nullOr (types.str);
              default = null;
              example = "textInputFocus";
              description = "Optional context filter.";
            };

            # https://code.visualstudio.com/docs/getstarted/keybindings#_command-arguments
            args = mkOption {
              type = types.nullOr (jsonFormat.type);
              default = null;
              example = { direction = "up"; };
              description = "Optional arguments for a command.";
            };
          };
        });
        default = [ ];
        example = literalExpression ''
          [
            {
              key = "ctrl+c";
              command = "editor.action.clipboardCopyAction";
              when = "textInputFocus";
            }
          ]
        '';
        description = ''
          Keybindings written to Visual Studio Code's
          <filename>keybindings.json</filename>.
        '';
      };

      extensions = mkOption {
        type = types.listOf types.package;
        default = [ ];
        example = literalExpression "[ pkgs.vscode-extensions.bbenoist.nix ]";
        description = ''
          The extensions Visual Studio Code should be started with.
        '';
      };

      mutableExtensionsDir = mkOption {
        type = types.bool;
        default = true;
        example = false;
        description = ''
          Whether extensions can be installed or updated manually
          or by Visual Studio Code.
        '';
      };

      mutableUserSettings = mkOption {
        type = types.bool;
        default = false;
        example = false;
        description = ''
          Whether user settings can be changed manually or by Visual
          Studio Code.
        '';
      };
    };
  };

  config = mkIf cfg.enable {
    home.packages = [ cfg.package ];

    home.file = mkMerge [
      (mkIf (!cfg.mutableUserSettings && cfg.userSettings != { }) {
        "${configFilePath}".source =
          jsonFormat.generate "vscode-user-settings" cfg.userSettings;
      })
      (mkIf (cfg.userTasks != { }) {
        "${tasksFilePath}".source =
          jsonFormat.generate "vscode-user-tasks" cfg.userTasks;
      })
      (mkIf (cfg.keybindings != [ ])
        (let dropNullFields = filterAttrs (_: v: v != null);
        in {
          "${keybindingsFilePath}".source =
            jsonFormat.generate "vscode-keybindings"
            (map dropNullFields cfg.keybindings);
        }))
      (mkIf (cfg.extensions != [ ]) (let
        subDir = "share/vscode/extensions";

        # Adapted from https://discourse.nixos.org/t/vscode-extensions-setup/1801/2
        toPaths = ext:
          map (k: { "${extensionPath}/${k}".source = "${ext}/${subDir}/${k}"; })
          (if ext ? vscodeExtUniqueId then
            [ ext.vscodeExtUniqueId ]
          else
            builtins.attrNames (builtins.readDir (ext + "/${subDir}")));
      in if cfg.mutableExtensionsDir then
        mkMerge (concatMap toPaths cfg.extensions)
      else {
        "${extensionPath}".source = let
          combinedExtensionsDrv = pkgs.buildEnv {
            name = "vscode-extensions";
            paths = cfg.extensions;
          };
        in "${combinedExtensionsDrv}/${subDir}";
      }))
    ];

    home.activation =
      mkIf (cfg.mutableUserSettings && cfg.userSettings != { }) {
        injectVscodeSettings = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
          tmp="$(mktemp)"
          if [[ -v DRY_RUN ]]; then
            echo tmp="\$(mktemp)"
            echo ${pkgs.jq}/bin/jq -s "'reduce .[] as \$x ({}; . * \$x)'" "${
              jsonFormat.generate "vscode-user-settings" cfg.userSettings
            }" "${configFilePath}" ">" "$tmp"
          else
            ${pkgs.jq}/bin/jq -s 'reduce .[] as $x ({}; . * $x)' "${
              jsonFormat.generate "vscode-user-settings" cfg.userSettings
            }" "${configFilePath}" > "$tmp"
          fi
          $DRY_RUN_CMD mv "$tmp" "${configFilePath}"
        '';
      };
  };
}
