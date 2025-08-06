{
  modulePath,
  name,
  package,
  packageName,
  configPaths ? { },
  multiProfile ? true,
}:
{
  config,
  lib,
  pkgs,
  ...
}:
let
  supportedApps = {
    "vscode" = "Code";
    "vscode-insiders" = "Code - Insiders";
    "vscodium" = "VSCodium";
    "openvscode-server" = "OpenVSCode Server";
    "windsurf" = "Windsurf";
    "cursor" = "Cursor";
  };

  jsonFormat = pkgs.formats.json { };

  appName = name;
  moduleName = lib.concatStringsSep "." modulePath;

  cfg = lib.getAttrFromPath modulePath config;

  vscodePname = cfg.package.pname;
  vscodeVersion = cfg.package.version;

  # User data directory
  #
  appUserDir =
    if pkgs.stdenv.hostPlatform.isDarwin then
      "${config.home.homeDirectory}/Library/Application Support/${appName}/User"
    else
      "${config.xdg.configHome}/${appName}/User";

  # Helper function to handle path vs JSON object logic
  mkJsonSource =
    name: value:
    if builtins.isPath value || lib.isStorePath value then
      value
    else
      jsonFormat.generate "vscode-${name}" value;

  getProfiles =
    let
      profiles = cfg.profiles or { };
    in

    # no profiles configured
    if profiles == { } then
      { }

    # multi-profile: return all profiles
    else if cfg.multiProfile then
      profiles

    # single profile: return default profile if it exists
    else if profiles ? default then
      { default = profiles.default; }

    # all else return empty
    else
      { };
in
{
  options = lib.setAttrByPath modulePath {
    enable = lib.mkEnableOption appName;
    package = lib.mkPackageOption pkgs packageName { };

    name = lib.mkOption {
      type = lib.types.str;
      internal = true;
      default = name;
      example = "VSCode";
      description = "The name of the VSCode fork.";
    };

    multiProfile = lib.mkOption {
      internal = true;
      type = lib.types.bool;
      default = multiProfile;
      example = false;
      description = "Whether the VSCode fork supports multiple profiles.";
    };

    configPaths = lib.mkOption {
      internal = true;
      type = lib.types.submodule {
        options = {
          mcp = lib.mkOption {
            type = lib.types.path;
            default = configPaths.mcp or "${appUserDir}/mcp.json";
            defaultText = lib.literalExpression ''"''${appUserDir}/mcp.json"'';
            example = "Library/Application Support/${appName}/User/mcp.json";
            description = "Path for MCP configuration file.";
          };

          tasks = lib.mkOption {
            type = lib.types.path;
            default = configPaths.tasks or "${appUserDir}/tasks.json";
            defaultText = lib.literalExpression ''"''${appUserDir}/tasks.json"'';
            example = "Library/Application Support/${appName}/User/tasks.json";
            description = "Path for tasks file.";
          };

          keybindings = lib.mkOption {
            type = lib.types.path;
            default = configPaths.keybindings or "${appUserDir}/keybindings.json";
            defaultText = lib.literalExpression ''"''${appUserDir}/keybindings.json"'';
            example = "Library/Application Support/${appName}/User/keybindings.json";
            description = "Path for keybindings file.";
          };

          extensions = lib.mkOption {
            type = lib.types.path;
            default = configPaths.extensions or "${appUserDir}/extensions";
            defaultText = lib.literalExpression ''"''${appUserDir}/extensions"'';
            example = "Library/Application Support/${appName}/User/extensions";
            description = "Path for the extensions directory.";
          };

          settings = lib.mkOption {
            type = lib.types.path;
            default = configPaths.settings or "${appUserDir}/settings.json";
            defaultText = lib.literalExpression ''"''${appUserDir}/settings.json"'';
            example = "Library/Application Support/${appName}/User/settings.json";
            description = "Path for settings file.";
          };
        };
      };
      default = { };
      description = "Custom path configuration for different file types.";
    };

    profiles = lib.mkOption {
      type = lib.types.attrsOf (
        lib.types.submodule {
          options = {
            extensions = lib.mkOption {
              type = lib.types.listOf lib.types.package;
              default = [ ];
              example = lib.literalExpression "[ pkgs.vscode-extensions.bbenoist.nix ]";
              description = "The extensions VSCode should be started with.";
            };

            keybindings = lib.mkOption {
              type = lib.types.either lib.types.path (
                lib.types.listOf (
                  lib.types.submodule {
                    options = {
                      key = lib.mkOption {
                        type = lib.types.str;
                        example = "ctrl+c";
                        description = "The key or key-combination to bind.";
                      };

                      command = lib.mkOption {
                        type = lib.types.str;
                        example = "editor.action.clipboardCopyAction";
                        description = "The VS Code command to execute.";
                      };

                      when = lib.mkOption {
                        type = lib.types.nullOr (lib.types.str);
                        default = null;
                        example = "textInputFocus";
                        description = "Optional context filter.";
                      };

                      # https://code.visualstudio.com/docs/getstarted/keybindings#_command-arguments
                      args = lib.mkOption {
                        type = lib.types.nullOr (jsonFormat.type);
                        default = null;
                        example = {
                          direction = "up";
                        };
                        description = "Optional arguments for a command.";
                      };
                    };
                  }
                )
              );
              default = [ ];
              example = lib.literalExpression ''
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
                {file}`keybindings.json`.
                This can be a JSON object or a path to a custom JSON file.
              '';
            };

            mcp = lib.mkOption {
              type = lib.types.either lib.types.path jsonFormat.type;
              default = { };
              example = lib.literalExpression ''
                {
                  "servers": {
                    "Github": {
                      "url": "https://api.githubcopilot.com/mcp/"
                    }
                  }
                }
              '';
              description = ''
                Configuration written to Visual Studio Code's
                {file}`mcp.json`.
                This can be a JSON object or a path to a custom JSON file.
              '';
            };

            settings = lib.mkOption {
              type = lib.types.either lib.types.path jsonFormat.type;
              default = { };
              example = lib.literalExpression ''
                {
                  "files.autoSave" = "off";
                  "[nix]"."editor.tabSize" = 2;
                }
              '';
              description = ''
                Configuration written to VSCode's {file}`settings.json`.
                This can be a JSON object or a path to a custom JSON file.
              '';
            };

            tasks = lib.mkOption {
              type = lib.types.either lib.types.path jsonFormat.type;
              default = { };
              example = lib.literalExpression ''
                {
                  version = "2.0.0";
                  tasks = [
                    {
                      type = "shell";
                      label = "Hello task";
                      command = "hello";
                    }
                  ];
                }
              '';
              description = ''
                Configuration written to VSCode's {file}`tasks.json`.
                This can be a JSON object or a path to a custom JSON file.
              '';
            };
          };
        }
      );
      default = { };
      description = "VSCode fork module configuration";
    };
  };

  config = lib.mkIf cfg.enable {
    home.packages = lib.mkIf (cfg.package != null) [ cfg.package ];

    home.file = lib.mkMerge (
      lib.flatten [
        (lib.mapAttrsToList (
          name: profile:
          let
            profilePath = mkProfilePath name;
          in
          [
            (builtins.trace "Generating ${appName} profile: ${name} (${profilePath})" { })

            # settings
            #
            (lib.mkIf (profile.settings != { }) {
              "${cfg.configPaths.settings}".source = mkJsonSource "user-settings" profile.settings;
            })

            # keybindings
            #
            (lib.mkIf (profile.keybindings != [ ]) {
              "${cfg.configPaths.keybindings}".source = mkJsonSource "keybindings" profile.keybindings;
            })

            # tasks
            #
            (lib.mkIf (profile.tasks != [ ]) {
              "${cfg.configPaths.tasks}".source = mkJsonSource "user-tasks" profile.tasks;
            })

            # mcp
            #
            (lib.mkIf (profile.mcp != { }) {
              "${cfg.configPaths.mcp}".source = mkJsonSource "user-mcp" profile.mcp;
            })
          ]
        ) getProfiles)
      ]
    );

    # Keep our test activation
    home.activation.testVscodeProfiles = ''
      echo "Configured profiles: ${lib.concatStringsSep ", " (lib.attrNames cfg.profiles)}"
    '';
  };
}
