{
  modulePath,
  name,
  package,
  packageName ? null,
  multiProfile ? true,
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

  defaultProfile = if cfg.profiles ? default then cfg.profiles.default else { };
  allProfilesExceptDefault = lib.removeAttrs cfg.profiles [ "default" ];

  mkProfilePath = name: "${appUserDir}${lib.optionalString (name != "default") "/profiles/${name}"}";

  extensionJson = ext: pkgs.vscode-utils.toExtensionJson ext;
  extensionJsonFile =
    name: text:
    pkgs.writeTextFile {
      inherit text;
      name = "extensions-json-${name}";
      destination = "/share/vscode/extensions/extensions.json";
    };

  # Helpers/derived values
  supportsProfileExtensionsJson =
    lib.versionAtLeast cfg.package.version "1.74.0"
    || builtins.elem cfg.package.pname [
      "cursor"
      "windsurf"
    ];

  hasDefaultProfile = defaultProfile != { };

  subDir = "share/vscode/extensions";

  allExtensions = lib.flatten (lib.mapAttrsToList (n: v: v.extensions) cfg.profiles);

  availableProfiles =
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
    package = lib.mkPackageOption pkgs appPackageName { };

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

    mutableExtensionsDir = lib.mkOption {
      type = lib.types.bool;
      default = allProfilesExceptDefault == { };
      defaultText = lib.literalExpression "(removeAttrs config.${lib.concatStringsSep "." modulePath}.profiles [ \"default\" ]) == { }";
      example = false;
      description = ''
        Whether extensions can be installed or updated manually or by Visual Studio Code only.
        Mutually exclusive to {option}`profiles`.

        It's automatically enabled by default if only default profile is set in {option}`profiles`.
      '';
    };

    debug = lib.mkOption {
      type = lib.types.bool;
      internal = true;
      default = false;
      description = "Enable verbose tracing during profile generation.";
    };

    overridePaths = lib.mkOption {
      internal = true;
      type = lib.types.submodule {
        options = {
          extensionsDir = lib.mkOption {
            type = lib.types.either lib.types.str lib.types.path;
            default = "~/.${lib.toLower appName}/extensions";
            example = "~/.vscode/extensions";
            description = "Path for the extensions directory.";
          };

          keybindingsFile = lib.mkOption {
            type = lib.types.nullOr lib.types.path;
            default = null;
            example = "Library/Application Support/${appName}/User/keybindings.json";
            description = "Path for keybindings file.";
          };

          mcpFile = lib.mkOption {
            type = lib.types.nullOr lib.types.path;
            default = null;
            example = "Library/Application Support/${appName}/User/mcp.json";
            description = "Path for MCP configuration file.";
          };

          settingsFile = lib.mkOption {
            type = lib.types.nullOr lib.types.path;
            default = null;
            example = "Library/Application Support/${appName}/User/settings.json";
            description = "Path for settings file.";
          };

          tasksFile = lib.mkOption {
            type = lib.types.nullOr lib.types.path;
            default = null;
            example = "Library/Application Support/${appName}/User/tasks.json";
            description = "Path for tasks file.";
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
        assertion = !(cfg.mutableExtensionsDir && allProfilesExceptDefault != { });
        message = "mutableExtensionsDir=true requires only a default profile; found additional profiles in ${lib.concatStringsSep ", " (builtins.attrNames allProfilesExceptDefault)}";
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
            profiles=(${lib.escapeShellArgs (builtins.attrNames allProfilesExceptDefault)})

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
          name: profile:
          let
            profilePath = mkProfilePath name;

            configFilePathFor =
              f:
              if (lib.getAttrFromPath [ "overridePaths" "${f}File" ] cfg) != null then
                lib.getAttrFromPath [ "overridePaths" "${f}File" ] cfg
              else
                "${profilePath}/${f}.json";
          in
          [
            (lib.mkIf cfg.debug (builtins.trace "Generating ${appName} profile: ${name} (${profilePath})" { }))

            # settings
            #
            (lib.mkIf (profile.settings != { }) {
              "${configFilePathFor "settings"}".source = mkJsonSource "user-settings" profile.settings;
            })

            # keybindings
            #
            (lib.mkIf (profile.keybindings != [ ]) {
              "${configFilePathFor "keybindings"}".source = mkJsonSource "keybindings" profile.keybindings;
            })

            # tasks
            #
            (lib.mkIf (profile.tasks != { }) {
              "${configFilePathFor "tasks"}".source = mkJsonSource "user-tasks" profile.tasks;
            })

            # mcp
            #
            (lib.mkIf (profile.mcp != { }) {
              "${configFilePathFor "mcp"}".source = mkJsonSource "user-mcp" profile.mcp;
            })
          ]
        ) availableProfiles)

        (lib.mkIf (cfg.profiles != { }) (
          let
            # Adapted from https://discourse.nixos.org/t/vscode-extensions-setup/1801/2
            toPaths =
              ext:
              map (k: { "${cfg.overridePaths.extensionsDir}/${k}".source = "${ext}/${subDir}/${k}"; }) (
                if ext ? vscodeExtUniqueId then
                  [ ext.vscodeExtUniqueId ]
                else
                  builtins.attrNames (builtins.readDir (ext + "/${subDir}"))
              );
          in
          if (cfg.mutableExtensionsDir && allProfilesExceptDefault == { }) then
            # Mutable extensions dir can only occur when only default profile is set.
            #
            # Force regenerating extensions.json using the below method,
            # causes VSCode to create the extensions.json with all the extensions
            # in the extension directory, which includes extensions from other profiles.
            lib.mkMerge (
              lib.concatMap toPaths allExtensions
              ++ lib.optional (supportsProfileExtensionsJson && hasDefaultProfile) {
                # Whenever our immutable extensions.json changes, force the profile to regenerate
                # extensions.json with both mutable and immutable extensions.
                "${cfg.overridePaths.extensionsDir}/.extensions-immutable.json" = {
                  text = extensionJson defaultProfile.extensions;
                  onChange = ''
                    run rm $VERBOSE_ARG -f "${cfg.overridePaths.extensionsDir}"/{extensions.json,.init-default-profile-extensions}
                    verboseEcho "Regenerating ${appName} extensions.json"
                    run ${lib.getExe cfg.package} --list-extensions > /dev/null
                  '';
                };
              }
            )
          else
            {
              "${cfg.overridePaths.extensionsDir}".source =
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
