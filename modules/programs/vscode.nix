{ config, lib, pkgs, ... }:

with lib;

let

  cfg = config.programs.vscode;

  vscodePname = cfg.package.pname;
  vscodeVersion = cfg.package.version;

  jsonFormat = pkgs.formats.json { };

  configDir = {
    "vscode" = "Code";
    "vscode-insiders" = "Code - Insiders";
    "vscodium" = "VSCodium";
    "openvscode-server" = "OpenVSCode Server";
    "windsurf" = "Windsurf";
    "cursor" = "Cursor";
  }.${vscodePname};

  extensionDir = {
    "vscode" = "vscode";
    "vscode-insiders" = "vscode-insiders";
    "vscodium" = "vscode-oss";
    "openvscode-server" = "openvscode-server";
    "windsurf" = "windsurf";
    "cursor" = "cursor";
  }.${vscodePname};

  userDir = if pkgs.stdenv.hostPlatform.isDarwin then
    "Library/Application Support/${configDir}/User"
  else
    "${config.xdg.configHome}/${configDir}/User";

  configFilePath = name:
    "${userDir}/${
      optionalString (name != "default") "profiles/${name}/"
    }settings.json";
  tasksFilePath = name:
    "${userDir}/${
      optionalString (name != "default") "profiles/${name}/"
    }tasks.json";
  keybindingsFilePath = name:
    "${userDir}/${
      optionalString (name != "default") "profiles/${name}/"
    }keybindings.json";

  snippetDir = name:
    "${userDir}/${
      optionalString (name != "default") "profiles/${name}/"
    }snippets";

  # TODO: On Darwin where are the extensions?
  extensionPath = ".${extensionDir}/extensions";

  extensionJson = ext: pkgs.vscode-utils.toExtensionJson ext;
  extensionJsonFile = name: text:
    pkgs.writeTextFile {
      inherit text;
      name = "extensions-json-${name}";
      destination = "/share/vscode/extensions/extensions.json";
    };

  mergedUserSettings =
    userSettings: enableUpdateCheck: enableExtensionUpdateCheck:
    userSettings
    // optionalAttrs (enableUpdateCheck == false) { "update.mode" = "none"; }
    // optionalAttrs (enableExtensionUpdateCheck == false) {
      "extensions.autoCheckUpdates" = false;
    };

  profileType = types.submodule {
    options = {
      userSettings = mkOption {
        type = jsonFormat.type;
        default = { };
        example = literalExpression ''
          {
            "files.autoSave" = "off";
            "[nix]"."editor.tabSize" = 2;
          }
        '';
        description = ''
          Configuration written to Visual Studio Code's
          {file}`settings.json`.
        '';
      };

      userTasks = mkOption {
        type = jsonFormat.type;
        default = { };
        example = literalExpression ''
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
          Configuration written to Visual Studio Code's
          {file}`tasks.json`.
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
          {file}`keybindings.json`.
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

      languageSnippets = mkOption {
        type = jsonFormat.type;
        default = { };
        example = {
          haskell = {
            fixme = {
              prefix = [ "fixme" ];
              body = [ "$LINE_COMMENT FIXME: $0" ];
              description = "Insert a FIXME remark";
            };
          };
        };
        description = "Defines user snippets for different languages.";
      };

      globalSnippets = mkOption {
        type = jsonFormat.type;
        default = { };
        example = {
          fixme = {
            prefix = [ "fixme" ];
            body = [ "$LINE_COMMENT FIXME: $0" ];
            description = "Insert a FIXME remark";
          };
        };
        description = "Defines global user snippets.";
      };

      enableUpdateCheck = mkOption {
        type = types.nullOr types.bool;
        default = null;
        description = ''
          Whether to enable update checks/notifications.
          Can only be set for the default profile, but
          it applies to all profiles.
        '';
      };

      enableExtensionUpdateCheck = mkOption {
        type = types.nullOr types.bool;
        default = null;
        description = ''
          Whether to enable update notifications for extensions.
          Can only be set for the default profile, but
          it applies to all profiles.
        '';
      };
    };
  };
  defaultProfile = if cfg.profiles ? default then cfg.profiles.default else { };
  allProfilesExceptDefault = removeAttrs cfg.profiles [ "default" ];
in {
  imports = [
    (mkChangedOptionModule [ "programs" "vscode" "immutableExtensionsDir" ] [
      "programs"
      "vscode"
      "mutableExtensionsDir"
    ] (config: !config.programs.vscode.immutableExtensionsDir))
  ] ++ map (v:
    mkRenamedOptionModule [ "programs" "vscode" v ] [
      "programs"
      "vscode"
      "profiles"
      "default"
      v
    ]) [
      "enableUpdateCheck"
      "enableExtensionUpdateCheck"
      "userSettings"
      "userTasks"
      "keybindings"
      "extensions"
      "languageSnippets"
      "globalSnippets"
    ];

  options.programs.vscode = {
    enable = mkEnableOption "Visual Studio Code";

    package = mkOption {
      type = types.package;
      default = pkgs.vscode;
      defaultText = literalExpression "pkgs.vscode";
      example = literalExpression "pkgs.vscodium";
      description = ''
        Version of Visual Studio Code to install.
      '';
    };

    mutableExtensionsDir = mkOption {
      type = types.bool;
      default = allProfilesExceptDefault == { };
      example = false;
      description = ''
        Whether extensions can be installed or updated manually
        or by Visual Studio Code. Mutually exclusive to
        programs.vscode.profiles.
      '';
    };

    profiles = mkOption {
      type = types.attrsOf profileType;
      default = { };
      description = ''
        A list of all VSCode profiles. Mutually exclusive
        to programs.vscode.mutableExtensionsDir
      '';
    };
  };

  config = mkIf cfg.enable {
    warnings = [
      (mkIf (allProfilesExceptDefault != { } && cfg.mutableExtensionsDir)
        "programs.vscode.mutableExtensionsDir can be used only if no profiles apart from default are set.")
      (mkIf ((filterAttrs (n: v:
        (v ? enableExtensionUpdateCheck || v ? enableUpdateCheck)
        && (v.enableExtensionUpdateCheck != null || v.enableUpdateCheck
          != null)) allProfilesExceptDefault) != { })
        "The option programs.vscode.profiles.*.enableExtensionUpdateCheck and option programs.vscode.profiles.*.enableUpdateCheck is invalid for all profiles except default.")
    ];

    home.packages = [ cfg.package ];

    # The file `${userDir}/globalStorage/storage.json` needs to be writable by VSCode,
    # since it contains other data, such as theme backgrounds, recently opened folders, etc.

    # A caveat of adding profiles this way is, VSCode has to be closed
    # when this file is being written, since the file is loaded into RAM
    # and overwritten on closing VSCode.
    home.activation.vscodeProfiles = hm.dag.entryAfter [ "writeBoundary" ] (let
      modifyGlobalStorage =
        pkgs.writeShellScript "vscode-global-storage-modify" ''
          PATH=${makeBinPath [ pkgs.jq ]}''${PATH:+:}$PATH
          file="${userDir}/globalStorage/storage.json"
          file_write=""
          profiles=(${
            escapeShellArgs
            (flatten (mapAttrsToList (n: v: n) allProfilesExceptDefault))
          })

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
    in modifyGlobalStorage.outPath);

    home.file = mkMerge (flatten [
      (mapAttrsToList (n: v: [
        (mkIf ((mergedUserSettings v.userSettings v.enableUpdateCheck
          v.enableExtensionUpdateCheck) != { }) {
            "${configFilePath n}".source =
              jsonFormat.generate "vscode-user-settings"
              (mergedUserSettings v.userSettings v.enableUpdateCheck
                v.enableExtensionUpdateCheck);
          })

        (mkIf (v.userTasks != { }) {
          "${tasksFilePath n}".source =
            jsonFormat.generate "vscode-user-tasks" v.userTasks;
        })

        (mkIf (v.keybindings != [ ]) {
          "${keybindingsFilePath n}".source =
            jsonFormat.generate "vscode-keybindings"
            (map (filterAttrs (_: v: v != null)) v.keybindings);
        })

        (mkIf (v.languageSnippets != { }) (mapAttrs' (language: snippet:
          nameValuePair "${snippetDir n}/${language}.json" {
            source =
              jsonFormat.generate "user-snippet-${language}.json" snippet;
          }) v.languageSnippets))

        (mkIf (v.globalSnippets != { }) {
          "${snippetDir n}/global.code-snippets".source =
            jsonFormat.generate "user-snippet-global.code-snippets"
            v.globalSnippets;
        })
      ]) cfg.profiles)

      # We write extensions.json for all profiles, except the default profile,
      # since that is handled by code below.
      (mkIf (allProfilesExceptDefault != { }) (mapAttrs' (n: v:
        nameValuePair "${userDir}/profiles/${n}/extensions.json" {
          source = "${
              extensionJsonFile n (extensionJson v.extensions)
            }/share/vscode/extensions/extensions.json";
        }) allProfilesExceptDefault))

      (mkIf (cfg.profiles != { }) (let
        # Adapted from https://discourse.nixos.org/t/vscode-extensions-setup/1801/2
        subDir = "share/vscode/extensions";
        toPaths = ext:
          map (k: { "${extensionPath}/${k}".source = "${ext}/${subDir}/${k}"; })
          (if ext ? vscodeExtUniqueId then
            [ ext.vscodeExtUniqueId ]
          else
            builtins.attrNames (builtins.readDir (ext + "/${subDir}")));
      in if (cfg.mutableExtensionsDir && allProfilesExceptDefault == { }) then
      # Mutable extensions dir can only occur when only default profile is set.
      # Force regenerating extensions.json using the below method,
      # causes VSCode to create the extensions.json with all the extensions
      # in the extension directory, which includes extensions from other profiles.
        mkMerge (concatMap toPaths
          (flatten (mapAttrsToList (n: v: v.extensions) cfg.profiles))
          ++ optional
          ((versionAtLeast vscodeVersion "1.74.0" || vscodePname == "cursor")
            && defaultProfile != { }) {
              # Whenever our immutable extensions.json changes, force VSCode to regenerate
              # extensions.json with both mutable and immutable extensions.
              "${extensionPath}/.extensions-immutable.json" = {
                text = extensionJson defaultProfile.extensions;
                onChange = ''
                  run rm $VERBOSE_ARG -f ${extensionPath}/{extensions.json,.init-default-profile-extensions}
                  verboseEcho "Regenerating VSCode extensions.json"
                  run ${getExe cfg.package} --list-extensions > /dev/null
                '';
              };
            })
      else {
        "${extensionPath}".source = let
          combinedExtensionsDrv = pkgs.buildEnv {
            name = "vscode-extensions";
            paths = (flatten (mapAttrsToList (n: v: v.extensions) cfg.profiles))
              ++ optional ((versionAtLeast vscodeVersion "1.74.0" || vscodePname
                == "cursor") && defaultProfile != { })
              (extensionJsonFile "default"
                (extensionJson defaultProfile.extensions));
          };
        in "${combinedExtensionsDrv}/${subDir}";
      }))
    ]);
  };
}
