{
  config,
  lib,
  pkgs,
  moduleName,
  packageName ? moduleName,
  dataFolderName ? ".${moduleName}",
  isInsiders ? false,
  ...
}:
let
  modulePath = [
    "programs"
    moduleName
  ];
  moduleConfig = lib.getAttrFromPath modulePath config;

  cfg = moduleConfig // {
    inherit isInsiders;

    dataFolderName =
      if moduleConfig ? dataFolderName && moduleConfig.dataFolderName != null then
        moduleConfig.dataFolderName
      else
        dataFolderName;

    homeDirectory =
      if pkgs.stdenv.hostPlatform.isDarwin then
        "${config.home.homeDirectory}"
      else
        "${config.xdg.configHome}";

    packageName =
      if moduleConfig ? packageName && moduleConfig.packageName != null then
        moduleConfig.packageName
      else
        packageName;
  };

  helpers = import ./path-helpers.nix {
    inherit lib pkgs;

    cfg = cfg // {
      package =
        if (moduleConfig ? package && moduleConfig.package != null) then
          moduleConfig.package
        else
          {
            version = "0.0.1";
            pname = packageName;
            longName = "${packageName} (VSCode Fork)";
            executableName = "${packageName}-fork";
          };
    };
  };

  profiles = import ./profiles/profiles.nix { inherit cfg lib pkgs; };
  snippets = import ./profiles/snippets.nix { inherit cfg lib pkgs; };
  extensions = import ./profiles/extensions.nix { inherit cfg lib pkgs; };

  homeFiles = lib.mkMerge (
    lib.flatten [
      profiles.configFiles
      snippets.snippetFiles
      extensions.extensionFiles
    ]
  );
in
{
  imports =
    # api.v2: migrate immutableExtensionsDir to mutableExtensionsDir
    [
      (lib.mkChangedOptionModule (modulePath ++ [ "immutableExtensionsDir" ]) (
        modulePath
        ++ [
          "mutableExtensionsDir"
        ]
      ) (config: !config.${lib.concatStringsSep "." modulePath}.immutableExtensionsDir))
    ]
  ++
    # api.v3: migrate top-level options to profiles.default
    map
      (
        v:
        lib.mkRenamedOptionModule (modulePath ++ [ v ]) (
          modulePath
          ++ [
            "profiles"
            "default"
            v
          ]
        )
      )
      [
        "enableUpdateCheck"
        "enableExtensionUpdateCheck"
        "userSettings"
        "userTasks"
        "userMcp"
        "keybindings"
        "extensions"
        "languageSnippets"
        "globalSnippets"
      ];

  options = lib.setAttrByPath modulePath {
    enable = lib.mkEnableOption "VSCode Fork: ${moduleName})";
    package = lib.mkPackageOption pkgs packageName { nullable = true; };

    name = lib.mkOption {
      internal = true;
      type = lib.types.str;
      default = helpers.appName;
      example = "VSCode";
      description = "The name of the VSCode fork. Used for internal purposes.";
    };

    packageName = lib.mkOption {
      internal = true;
      type = lib.types.nullOr lib.types.str;
      default = packageName;
      example = "code-cursor";
      description = "The name of the VSCode fork package. Used for internal purposes.";
    };

    dataFolderName = lib.mkOption {
      internal = true;
      type = lib.types.nullOr lib.types.str;
      default = dataFolderName;
      example = ".vscode-oss";
      description = "The name of the VSCode fork data folder. Used for internal purposes.";
    };

    mutableExtensionsDir = lib.mkOption {
      type = lib.types.bool;
      default = profiles.otherProfiles == { };
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
      default = profiles.otherProfiles == { };
      defaultText = lib.literalExpression "(removeAttrs config.${lib.concatStringsSep "." modulePath}.profiles [ \"default\" ]) == { }";
      example = false;
      description = ''
        Whether the profile supports mutable profile settings, keybindings, tasks, and MCP configuration.

        This option allows to write settings to the profile's {file}`settings.json` file,
        which is regenerated whenever the nix configuration for the profile's `settings` are changed.

        This option is automatically enabled if only the {option}`profiles.default` profile is set.
      '';
    };

    profiles = lib.mkOption {
      type = lib.types.attrsOf (
        lib.types.submodule {
          # api.v4: migrate old profile options names to new names within profiles.default
          imports = [
            (lib.mkRenamedOptionModule [ "globalSnippets" ] [ "snippets" "global" ])
            (lib.mkRenamedOptionModule [ "languageSnippets" ] [ "snippets" "languages" ])
            (lib.mkRenamedOptionModule [ "userMcp" ] [ "mcp" ])
            (lib.mkRenamedOptionModule [ "userSettings" ] [ "settings" ])
            (lib.mkRenamedOptionModule [ "userTasks" ] [ "tasks" ])
          ];

          options = {
            enableUpdateCheck = lib.mkOption {
              type = lib.types.nullOr lib.types.bool;
              default = null;
              description = ''
                Whether to enable update checks/notifications.
                Can only be set for the default profile, but
                it applies to all profiles.
              '';
            };

            enableExtensionUpdateCheck = lib.mkOption {
              type = lib.types.nullOr lib.types.bool;
              default = null;
              description = ''
                Whether to enable update notifications for extensions.
                Can only be set for the default profile, but
                it applies to all profiles.
              '';
            };

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
                        type = lib.types.nullOr (helpers.jsonFormat.type);
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
              type = lib.types.either lib.types.path helpers.jsonFormat.type;
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
              type = lib.types.either lib.types.path helpers.jsonFormat.type;
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

            snippets = lib.mkOption {
              type = lib.types.submodule {
                options = {
                  global = lib.mkOption {
                    type = lib.types.either lib.types.path helpers.jsonFormat.type;
                    default = { };
                    description = "Global user snippets";
                  };
                  languages = lib.mkOption {
                    type = lib.types.attrsOf (lib.types.either lib.types.path helpers.jsonFormat.type);
                    default = { };
                    description = "Language-specific user snippets";
                  };
                };
              };
              default = { };
              example = {
                global = {
                  fixme = {
                    prefix = [ "fixme" ];
                    body = [ "$LINE_COMMENT FIXME: $0" ];
                    description = "Insert a FIXME remark";
                  };
                };
                languages = {
                  haskell = {
                    fixme = {
                      prefix = [ "fixme" ];
                      body = [ "$LINE_COMMENT FIXME: $0" ];
                      description = "Insert a FIXME remark";
                    };
                  };
                };
              };
              description = "Defines user snippets (both global and language-specific).";
            };

            tasks = lib.mkOption {
              type = lib.types.either lib.types.path helpers.jsonFormat.type;
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
        assertion = !(cfg.mutableExtensionsDir && profiles.otherProfiles != { });
        message = "mutableExtensionsDir=true requires only a default profile; found additional profiles in ${lib.concatStringsSep ", " (builtins.attrNames profiles.otherProfiles)}";
      }
    ];

    home.packages = lib.mkIf (cfg.package != null) [ cfg.package ];

    home.file = homeFiles;

    # The file `${appUserDir}/globalStorage/storage.json` needs to be writable by VSCode,
    # since it contains other data, such as theme backgrounds, recently opened folders, etc.

    # A caveat of adding profiles this way is, VSCode has to be closed
    # when this file is being written, since the file is loaded into RAM
    # and overwritten on closing VSCode.
    home.activation = {
      "vscodeProfilesFor${helpers.appName}" = lib.hm.dag.entryAfter [ "writeBoundary" ] (
        let
          modifyGlobalStorage = pkgs.writeShellScript "vscode-global-storage-modify" ''
            set -euo pipefail
            PATH=${lib.makeBinPath [ pkgs.jq ]}''${PATH:+:}$PATH
            file="${helpers.userDirectory}/globalStorage/storage.json"
            file_write=""
            profiles=(${lib.escapeShellArgs (builtins.attrNames profiles.otherProfiles)})

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
  };
}
