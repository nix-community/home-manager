{
  config,
  lib,
  pkgs,
  ...
}:
let
  jsonFormat = pkgs.formats.json { };

  cfg = config.programs.vscode-profiles;
  vscodePname = cfg.package.pname;
  vscodeVersion = cfg.package.version;

  configDir =
    {
      "vscode" = "Code";
      "vscode-insiders" = "Code - Insiders";
      "vscodium" = "VSCodium";
      "openvscode-server" = "OpenVSCode Server";
      "windsurf" = "Windsurf";
      "cursor" = "Cursor";
    }
    .${vscodePname};

  userDir =
    if pkgs.stdenv.hostPlatform.isDarwin then
      "${config.home.homeDirectory}/Library/Application Support/${configDir}/User"
    else
      "${config.xdg.configHome}/${configDir}/User";

  profilePath = name: "${userDir}${lib.optionalString (name != "default") "/profiles/${name}"}";

  snippetDir = name: "${profilePath name}/snippets";

  isPath = path: builtins.isPath path || lib.isStorePath path;

  # Helper function to handle path vs JSON object logic
  mkJsonSource =
    name: value: if isPath value then value else jsonFormat.generate "vscode-${name}" value;
in
{
  options.programs.vscode-profiles = {
    enable = lib.mkEnableOption "VSCode profiles extension";
    package = lib.mkPackageOption pkgs "code-cursor" { };

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
      description = "VSCode profiles configuration";
    };
  };

  config = lib.mkIf cfg.enable {
    home.packages = lib.mkIf (cfg.package != null) [ cfg.package ];

    home.file = lib.mkMerge (
      lib.flatten [
        (lib.mapAttrsToList (name: profile: [
          # settings
          #
          (lib.mkIf (profile.settings != { }) {
            "${profilePath name}/settings.json".source = mkJsonSource "user-settings" profile.settings;
          })

          # keybindings
          #
          (lib.mkIf (profile.keybindings != [ ]) {
            "${profilePath name}/keybindings.json".source = mkJsonSource "keybindings" (
              map (lib.filterAttrs (_: v: v != null)) profile.keybindings
            );
          })

          # tasks
          #
          (lib.mkIf (profile.tasks != [ ]) {
            "${profilePath name}/tasks.json".source = mkJsonSource "user-tasks" profile.tasks;
          })

          # mcp
          #
          (lib.mkIf (profile.mcp != { }) {
            "${profilePath name}/mcp.json".source = mkJsonSource "user-mcp" profile.mcp;
          })
        ]) cfg.profiles)
      ]
    );

    # Keep our test activation
    home.activation.testVscodeProfiles = ''
      echo "Configured profiles: ${lib.concatStringsSep ", " (lib.attrNames cfg.profiles)}"
    '';
  };
}
