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

  isMcpGlobalEnabled =
    config.programs.mcp.enable
    && config.programs.mcp.servers != { }
    && config.programs.mcp.servers != null;

  #  servers config from MCP module to VSCode MCP config format
  # acting as a global MCP config for the VSCode fork
  #
  globalMcpServers =
    if isMcpGlobalEnabled then
      lib.mapAttrs' (
        name: server:
        let
          urlServer = {
            type = "remote";
            url = server.url;
          }
          // (lib.optionalAttrs (server ? headers) { headers = server.headers; });

          commandServer = {
            type = "local";
            command = [ server.command ] ++ (server.args or [ ]);
          }
          // (lib.optionalAttrs (server ? env) { environment = server.env; });
        in
        lib.nameValuePair name (
          {
            enabled = !(server.disabled or false);
          }
          // (lib.optionalAttrs (server ? url) urlServer)
          // (lib.optionalAttrs (server ? command) commandServer)
          // (lib.removeAttrs server [ "disabled" ])
        )
      ) config.programs.mcp.servers
    else
      { };

  cfg = moduleConfig // {
    inherit (config.home) homeDirectory;
    inherit globalMcpServers isInsiders;

    dataFolderName =
      if moduleConfig ? dataFolderName && moduleConfig.dataFolderName != null then
        moduleConfig.dataFolderName
      else
        dataFolderName;

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
  imports = [
    ./vscode-haskell.nix # add haskell support if enabled (only vscode is supported)
  ]
  ++
    # api.v2: migrate immutableExtensionsDir to mutableExtensionsDir
    [
      (lib.mkChangedOptionModule (modulePath ++ [ "immutableExtensionsDir" ]) (
        modulePath ++ [ "mutableExtensionsDir" ]
      ) (config: !(lib.getAttrFromPath (modulePath ++ [ "immutableExtensionsDir" ]) config)))
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
          # api.v4: automatically migrates any obsolete profile options without warnings
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

            enableMcpIntegration = lib.mkOption {
              type = lib.types.bool;
              default = false;
              description = ''
                Whether to integrate the MCP servers config from
                {option}`programs.mcp.servers` into
                {option}`programs.vscode.profiles.<name>.mcp`.

                Note: Settings defined in {option}`programs.mcp.servers` are merged
                with {option}`programs.vscode.profiles.<name>.mcp`, with VSCode
                settings taking precedence.
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
                # VSCode format
                {
                  "servers": {
                    "Github": {
                      "url": "https://api.githubcopilot.com/mcp/"
                    }
                  }
                }

                # Cursor format
                {
                  "mcpServers": {
                    "Github": {
                      "url": "https://api.githubcopilot.com/mcp/"
                    }
                  }
                }
              '';
              description = ''
                Configuration written to the profile's {file}`mcp.json`.
                This can be a JSON object or a path to a custom JSON file.

                Please note that some VSCode forks, such as Cursor, have a different MCP configuration format.
                For example, Cursor uses the `mcpServers` key instead of `servers`.
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
    warnings =
      let
        getOtherProfiles = lib.removeAttrs cfg.profiles [ "default" ];
        hasOtherProfiles = getOtherProfiles != { };
      in
      [
        (lib.mkIf (cfg.mutableExtensionsDir && hasOtherProfiles)
          "programs.${moduleName}.profiles.*.mutableExtensionsDir only has effect for the default profile when no other profiles are set."
        )

        (lib.mkIf
          (
            (lib.filterAttrs (
              n: v:
              (v ? enableExtensionUpdateCheck || v ? enableUpdateCheck)
              && (v.enableExtensionUpdateCheck != null || v.enableUpdateCheck != null)
            ) getOtherProfiles) != { }
          )
          "programs.${moduleName}.profiles.*.enableUpdateCheck and programs.${moduleName}.profiles.*.enableExtensionUpdateCheck only have effect for the default profile."
        )
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
                if [[ "$(echo $existing_profiles | jq --arg profile "$profile" 'has ($profile)')" != "true" ]] || [[ "$(echo $existing_profiles | jq --arg profile "$profile" 'has ($profile)')" == "true" && "$(echo $existing_profiles | jq --arg profile "$profile" '.[$profile]')" != "\"$profile\"" ]]; then
                  file_write="$file_write$([ "$file_write" != "" ] && echo "...")$profile"
                fi
              done
            else
              for profile in "''${profiles[@]}"; do
                file_write="$file_write$([ "$file_write" != "" ] && echo "...")$profile"
              done

              mkdir -p "$(dirname "$file")"
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
