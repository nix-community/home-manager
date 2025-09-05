{
  modulePath,
  name,
  package,
  packageName ? null,
  configDirName ? name,
  overridePaths ? { },
}:
{
  config,
  lib,
  pkgs,
  ...
}:
let
  jsonFormat = pkgs.formats.json { };

  cfg = lib.getAttrFromPath modulePath config;

  appName = name;
  appPackageName = if (packageName != null) then packageName else package.pname;

  # https://code.visualstudio.com/docs/configure/settings#_settings-precedence
  # https://code.visualstudio.com/docs/configure/settings#_settings-json-file
  #
  # app user directory
  #
  appUserDir =
    if pkgs.stdenv.hostPlatform.isDarwin then
      "${config.home.homeDirectory}/Library/Application Support/${configDirName}/User"
    else
      "${config.xdg.configHome}/${configDirName}/User";

  # Helper function to handle path vs JSON object logic
  toJsonSource =
    name: value:
    if builtins.isPath value || lib.isStorePath value then
      builtins.trace "is a path: ${value}" value
    else
      builtins.trace "is a json: ${jsonFormat.generate "${appPackageName}-${name}" value}"
        jsonFormat.generate
        "${appPackageName}-${name}"
        value;

  # profiles
  #
  defaultProfile = if cfg.profiles ? default then cfg.profiles.default else { };
  otherProfiles = lib.removeAttrs cfg.profiles [ "default" ];

  hasDefaultProfile = cfg.profiles ? default;

  buildProfilePath =
    name: "${appUserDir}${lib.optionalString (name != "default") "/profiles/${name}"}";

  configFilePathFor =
    profileName: key:
    if overridePaths ? "${key}" && overridePaths.${key} != null then
      builtins.trace "override path for ${profileName} -> ${key}: ${overridePaths.${key}}"
        overridePaths.${key}
    else
      builtins.trace "default path for ${profileName} -> ${key}: ${buildProfilePath profileName}" (
        buildProfilePath profileName
      );

  # extensions
  #
  appExtensionsPath =
    if overridePaths ? extensions && overridePaths.extensions != null then
      overridePaths.extensions
    else
      builtins.trace "appExtensionsPath: ${config.home.homeDirectory}/.${lib.toLower configDirName}/extensions" "${config.home.homeDirectory}/.${lib.toLower configDirName}/extensions";

  allExtensions = lib.flatten (lib.mapAttrsToList (n: v: v.extensions) cfg.profiles);
  extensionJson = ext: pkgs.vscode-utils.toExtensionJson ext;
  extensionJsonFile =
    name: text:
    pkgs.writeTextFile {
      inherit text;
      name = "extensions-json-${name}";
      destination = "/share/vscode/extensions/extensions.json";
    };

  supportsProfileExtensionsJson =
    let
      versionCheck = lib.versionAtLeast cfg.package.version "1.74.0";
      pnameCheck = builtins.elem cfg.package.pname [
        "code-cursor"
        "windsurf"
      ];
    in
    builtins.trace
      "Checking profile extensions support for ${cfg.package.pname} ${cfg.package.version}: versionCheck=${toString versionCheck}, pnameCheck=${toString pnameCheck}"
      (versionCheck || pnameCheck);

in
{
  options = lib.setAttrByPath modulePath {
    enable = lib.mkEnableOption appName;
    package = lib.mkPackageOption pkgs appPackageName { };

    name = lib.mkOption {
      type = lib.types.str;
      internal = true;
      default = name;
      example = "VSCode";
      description = "The name of the VSCode fork.";
    };

    mutableExtensionsDir = lib.mkOption {
      type = lib.types.bool;
      default = otherProfiles == { };
      defaultText = lib.literalExpression "(removeAttrs config.${lib.concatStringsSep "." modulePath}.profiles [ \"default\" ]) == { }";
      example = false;
      description = ''
        Whether extensions can be installed or updated manually or by Visual Studio Code only.
        This option is mutually exclusive to {option}`profiles` and it's automatically enabled
        if only `default` profile is set in {option}`profiles`.
      '';
    };

    mutableProfile = lib.mkOption {
      type = lib.types.bool;
      default = otherProfiles == { };
      defaultText = lib.literalExpression "(removeAttrs config.${lib.concatStringsSep "." modulePath}.profiles [ \"default\" ]) == { }";
      example = false;
      description = ''
        Whether the profile supports mutable profile settings, keybindings, tasks, and MCP configuration.

        This option allows to write settings to the profile's {file}`settings.json` file,
        which is regenerated whenever the nix configuration for the profile's `settings` are changed.

        This option is automatically enabled if only the {option}`profiles.default` profile is set.
      '';
    };

    overridePaths = lib.mkOption {
      internal = true;
      type = lib.types.submodule {
        options = {
          extensions = lib.mkOption {
            type = lib.types.nullOr lib.types.path;
            default = null;
            example = ".${lib.toLower appName}/extensions";
            description = "Directory where extensions are stored.";
          };

          keybindings = lib.mkOption {
            type = lib.types.nullOr lib.types.path;
            default = null;
            example = "Library/Application Support/${appName}/User";
            description = "Path where keybindings file is stored.";
          };

          mcp = lib.mkOption {
            type = lib.types.nullOr lib.types.path;
            default = null;
            example = "Library/Application Support/${appName}/User";
            description = "Path where MCP configuration file is stored.";
          };

          settings = lib.mkOption {
            type = lib.types.nullOr lib.types.path;
            default = null;
            example = "Library/Application Support/${appName}/User";
            description = "Path where settings file is stored.";
          };

          tasks = lib.mkOption {
            type = lib.types.nullOr lib.types.path;
            default = null;
            example = "Library/Application Support/${appName}/User";
            description = "Path where tasks file is stored.";
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
              description = "The extensions to be installed in the profile.";
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
                        description = "The command to execute.";
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
                Keybindings written to the profile's {file}`keybindings.json`.
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
                Configuration written to the profile's {file}`mcp.json`.
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
                Configuration written to the profile's {file}`settings.json`.
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
                Configuration written to the profile's {file}`tasks.json`.
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
    assertions = [
      {
        assertion = !(cfg.mutableExtensionsDir && otherProfiles != { });
        message = "mutableExtensionsDir=true requires only a default profile; found additional profiles in ${lib.concatStringsSep ", " (builtins.attrNames otherProfiles)}";
      }
    ];
    home.packages = lib.mkIf (cfg.package != null) [ cfg.package ];

    # The file `${appUserDir}/globalStorage/storage.json` needs to be writable by VSCode,
    # since it contains other data, such as theme backgrounds, recently opened folders, etc.

    # A caveat of adding profiles this way is, VSCode has to be closed
    # when this file is being written, since the file is loaded into RAM
    # and overwritten on closing VSCode.
    home.activation = {
      "vscodeProfilesFor${appName}" = lib.hm.dag.entryAfter [ "writeBoundary" ] (
        let
          modifyGlobalStorage = pkgs.writeShellScript "vscode-global-storage-modify" ''
            set -euo pipefail
            PATH=${lib.makeBinPath [ pkgs.jq ]}''${PATH:+:}$PATH
            file="${appUserDir}/globalStorage/storage.json"
            file_write=""
            profiles=(${lib.escapeShellArgs (builtins.attrNames otherProfiles)})

            if [ -f "$file" ]; then
              existing_profiles=$(jq '.userDataProfiles // [] | map({ (.name): .location }) | add // {}' "$file")

              for profile in "''${profiles[@]}"; do
                if [[ "$(echo $existing_profiles | jq --arg profile $profile 'has ($profile)')" != "true" ]] || [[ "$(echo $existing_profiles | jq --arg profile $profile 'has ($profile)')" == "true" && "$(echo $existing_profiles | jq --arg profile $profile '.[$profile]')" != "\"$profile\"" ]]; then
                  file_write="$file_write$([ "$file_write" != "" ] && echo "...")$profile"
                fi
              done
            else
              for profile in "''${profiles[@]}"; do
                file_write="$file_write$([ "$file_write" != "" ] && echo "...")$profile"
              done

              mkdir -p $(dirname "$file")
              echo "{}" > "$file"
            fi

            if [ "$file_write" != "" ]; then
              userDataProfiles=$(jq ".userDataProfiles += $(echo $file_write | jq -R 'split("...") | map({ name: ., location: . })')" "$file")
              echo $userDataProfiles > "$file"
            fi
          '';
        in
        modifyGlobalStorage.outPath
      );
    };

    home.file = lib.mkMerge (
      lib.flatten [
        (lib.mapAttrsToList (
          profileName: profile:
          let
            settingsPath = configFilePathFor profileName "settings";
            keybindingsPath = configFilePathFor profileName "keybindings";
            tasksPath = configFilePathFor profileName "tasks";
            mcpPath = configFilePathFor profileName "mcp";
          in
          [
            (builtins.trace "building ${appName} ${
              if cfg.mutableProfile then "mutable" else "immutable"
            } profile: ${profileName} (${buildProfilePath profileName})" { })

            # settings
            #
            (lib.mkIf (profile.settings != { }) {
              "${settingsPath}/${lib.optionalString cfg.mutableProfile ".immutable-"}settings.json" = {
                source = toJsonSource "user-settings" profile.settings;
                onChange = lib.mkIf cfg.mutableProfile ''
                  run cp -v "${settingsPath}/.immutable-settings.json" "${settingsPath}/settings.json"
                  verboseEcho "Regenerating mutable ${settingsPath}/settings.json"
                '';
              };
            })

            # keybindings
            #
            (lib.mkIf (profile.keybindings != [ ]) {
              "${keybindingsPath}/${lib.optionalString cfg.mutableProfile ".immutable-"}keybindings.json" = {
                source = toJsonSource "user-keybindings" profile.keybindings;
                onChange = lib.mkIf cfg.mutableProfile ''
                  run cp -v "${keybindingsPath}/.immutable-keybindings.json" "${keybindingsPath}/keybindings.json"
                  verboseEcho "Regenerating mutable ${keybindingsPath}/keybindings.json"
                '';
              };
            })

            # tasks
            #
            (lib.mkIf (profile.tasks != { }) {
              "${tasksPath}/${lib.optionalString cfg.mutableProfile ".immutable-"}tasks.json" = {
                source = toJsonSource "user-tasks" profile.tasks;
                onChange = lib.mkIf cfg.mutableProfile ''
                  run cp -v "${tasksPath}/.immutable-tasks.json" "${tasksPath}/tasks.json"
                  verboseEcho "Regenerating mutable ${tasksPath}/tasks.json"
                '';
              };
            })

            # mcp
            #
            (lib.mkIf (profile.mcp != { }) {
              "${mcpPath}/${lib.optionalString cfg.mutableProfile ".immutable-"}mcp.json" = {
                source = toJsonSource "user-mcp" profile.mcp;
                onChange = lib.mkIf cfg.mutableProfile ''
                  run cp -v "${mcpPath}/.immutable-mcp.json" "${mcpPath}/mcp.json"
                  verboseEcho "Regenerating mutable ${mcpPath}/mcp.json"
                '';
              };
            })
          ]
        ) cfg.profiles)

        (lib.mkIf (cfg.profiles != { }) (
          let
            # Adapted from https://discourse.nixos.org/t/vscode-extensions-setup/1801/2
            subDir = "share/vscode/extensions";

            toPaths =
              ext:
              map (k: { "${appExtensionsPath}/${k}".source = "${ext}/${subDir}/${k}"; }) (
                if ext ? vscodeExtUniqueId then
                  [ ext.vscodeExtUniqueId ]
                else
                  builtins.attrNames (builtins.readDir (ext + "/${subDir}"))
              );
          in
          if (cfg.mutableExtensionsDir && otherProfiles == { }) then
            # Mutable extensions dir can only occur when only default profile is set.
            #
            # Force regenerating extensions.json using the below method,
            # causes VSCode to create the extensions.json with all the extensions
            # in the extension directory, which includes extensions from other profiles.
            lib.mkMerge (
              builtins.trace "Mapping paths for extensions: ${toString allExtensions}" (
                lib.concatMap toPaths allExtensions
                ++
                  lib.optional
                    (builtins.trace
                      "Checking profile extensions support: supportsProfileExtensionsJson=${toString supportsProfileExtensionsJson}, hasDefaultProfile=${toString hasDefaultProfile}"
                      (supportsProfileExtensionsJson && hasDefaultProfile)
                    )
                    {
                      # Whenever our immutable extensions.json changes, force the profile to regenerate
                      # extensions.json with both mutable and immutable extensions.
                      "${appExtensionsPath}/.extensions-immutable.json" = {
                        text = builtins.trace "Generating extension JSON for default profile" (
                          extensionJson defaultProfile.extensions
                        );
                        onChange = ''
                          run rm $VERBOSE_ARG -f "${appExtensionsPath}"/{extensions.json,.init-default-profile-extensions}
                          verboseEcho "Regenerating ${appName} extensions.json"
                          run ${lib.getExe cfg.package} --list-extensions > /dev/null
                        '';
                      };
                    }
              )
            )
          else
            {
              "${appExtensionsPath}".source =
                let
                  combinedExtensionsDrv = pkgs.buildEnv {
                    name = "vscode-extensions";
                    paths =
                      allExtensions
                      ++ lib.optional (supportsProfileExtensionsJson && hasDefaultProfile) (
                        extensionJsonFile "default" (extensionJson defaultProfile.extensions)
                      );
                  };
                in
                "${combinedExtensionsDrv}/${subDir}";
            }
        ))
      ]
    );
  };
}
