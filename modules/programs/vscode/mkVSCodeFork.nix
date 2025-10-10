{
  modulePath,
  name,
  package,
  packageName ? null,
  configDirectory ? ".${name}",
  userDirectory ? name,
  overridePaths ? { },
}:
{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = lib.getAttrFromPath modulePath config // {
    inherit overridePaths configDirectory userDirectory;
  };

  helpers = import ./path-helpers.nix { inherit cfg lib pkgs; };

  # configs per profile that are supported by this module
  #
  configsPerProfile = [
    "settings"
    "keybindings"
    "tasks"
    "mcp"
  ];

  # Generates configuration files for each profile key that exists and is non-empty
  #
  # For each key in configsPerProfile:
  # - If the profile has the key AND the value is not an empty set
  # - Creates a config file with the appropriate path (mutable/immutable)
  # - Sets up change handler for mutable profiles to regenerate configs
  #
  # Returns: List of attribute sets ready for home-manager file configuration
  mkConfigsPerProfile =
    profileName: profile:
    lib.concatMap (
      key:
      lib.optionals ((profile ? "${key}") && (profile.${key} != { })) [
        {
          "${helpers.mkProfileConfigPathBuilder profileName key cfg.mutableProfile}" = {
            source = toJsonSource "user-${key}" profile.${key};

            onChange = lib.mkIf cfg.mutableProfile ''
              run cp -v "${helpers.mkImmutableConfigPath profileName key}" "${helpers.mkMutableConfigPath profileName key}"

              verboseEcho "Regenerating mutable: ${helpers.mkMutableConfigPath profileName key}"
            '';
          };
        }
      ]
    ) configsPerProfile;

  appName = name;
  appPackageName = if (packageName != null) then packageName else package.pname;

  jsonFormat = pkgs.formats.json { };

  # Helper function to handle path vs JSON object logic
  toJsonSource =
    name: value:
    if builtins.isPath value || lib.isStorePath value then
      builtins.trace "is a path: ${value}" value
    else
      builtins.trace "is a json: ${jsonFormat.generate "${appPackageName}-${name}" value}"
        jsonFormat.generate
        "${appPackageName}-${name}-json"
        value;

  # profiles
  #
  defaultProfile = if cfg.profiles ? default then cfg.profiles.default else { };
  otherProfiles = lib.removeAttrs cfg.profiles [ "default" ];

  hasDefaultProfile = cfg.profiles ? default;

  # extensions
  #
  appExtensionsPath =
    if overridePaths ? extensions && overridePaths.extensions != null then
      overridePaths.extensions
    else
      "${configDirectory}/extensions";

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
    (versionCheck || pnameCheck);

  # Consolidated flags and helpers for extensions handling
  supportsDefaultProfileJson = supportsProfileExtensionsJson && hasDefaultProfile;

  # Adapted from https://discourse.nixos.org/t/vscode-extensions-setup/1801/2
  subDir = "share/vscode/extensions";

  toExtensionPathAttrs =
    ext:
    map (k: { "${appExtensionsPath}/${k}".source = "${ext}/${subDir}/${k}"; }) (
      if ext ? vscodeExtUniqueId then
        [ ext.vscodeExtUniqueId ]
      else
        builtins.attrNames (builtins.readDir (ext + "/${subDir}"))
    );

  mkMutableExtensionsFiles = lib.mkMerge (
    builtins.trace "Mapping paths for extensions: ${toString allExtensions}" (
      lib.concatMap toExtensionPathAttrs allExtensions
      ++
        lib.optional
          (builtins.trace "Checking profile extensions support: supportsProfileExtensionsJson=${toString supportsProfileExtensionsJson}, hasDefaultProfile=${toString hasDefaultProfile}" supportsDefaultProfileJson)
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
  );

  mkImmutableExtensionsFiles = {
    "${appExtensionsPath}".source =
      let
        combinedExtensionsDrv = pkgs.buildEnv {
          name = "vscode-extensions";
          paths =
            allExtensions
            ++ lib.optional supportsDefaultProfileJson (
              extensionJsonFile "default" (extensionJson defaultProfile.extensions)
            );
        };
      in
      "${combinedExtensionsDrv}/${subDir}";
  };
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
            file="${helpers.mkAppUserDir}/globalStorage/storage.json"
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
        (lib.mapAttrsToList mkConfigsPerProfile cfg.profiles)

        (lib.mkIf (cfg.profiles != { }) (
          if (cfg.mutableExtensionsDir && otherProfiles == { }) then
            mkMutableExtensionsFiles
          else
            mkImmutableExtensionsFiles
        ))
      ]
    );
  };
}
