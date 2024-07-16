{ config, lib, pkgs, ... }:

# TODO: Re-write tests to support profiles.

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
  }.${vscodePname};

  extensionDir = {
    "vscode" = "vscode";
    "vscode-insiders" = "vscode-insiders";
    "vscodium" = "vscode-oss";
    "openvscode-server" = "openvscode-server";
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

  mergedUserSettings = userSettings:
    userSettings
    // optionalAttrs (!cfg.enableUpdateCheck) { "update.mode" = "none"; }
    // optionalAttrs (!cfg.enableExtensionUpdateCheck) {
      "extensions.autoCheckUpdates" = false;
    };

  profileType = default:
    types.submodule {
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
      } // optionalAttrs default {
        name = mkOption {
          type = types.str;
          description = "Visual Studio Code's Profile name.";
        };
      };
    };
  allProfiles = cfg.profiles ++ [ cfg.defaultProfile ];
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
      "defaultProfile"
      v
    ]) [
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

    enableUpdateCheck = mkOption {
      type = types.bool;
      default = true;
      description = ''
        Whether to enable update checks/notifications.
      '';
    };

    enableExtensionUpdateCheck = mkOption {
      type = types.bool;
      default = true;
      description = ''
        Whether to enable update notifications for extensions.
      '';
    };

    mutableExtensionsDir = mkOption {
      type = types.bool;
      default = cfg.profiles == [ ];
      example = false;
      description = ''
        Whether extensions can be installed or updated manually
        or by Visual Studio Code. This option is effective only
        when there is a single profile (i.e. default).
      '';
    };

    profiles = mkOption {
      type = types.listOf (profileType true);
      default = [ ];
    };
    defaultProfile = mkOption {
      type = profileType false;
      default = { };
    };
  };

  config = mkIf cfg.enable {
    warnings = [
      (mkIf (cfg.profiles != [ ] && cfg.mutableExtensionsDir)
        "programs.vscode.mutableExtensionsDir can be used only if profiles is an empty list.")
    ];

    home.packages = [ cfg.package ];

    /* *
       TODO: Write a home.activation script for ${userDir}/globalStorage/storage.json, appending
       every profile in the format `{ "name": <profile_name>, "location": <profile_name> }` to the
       userDataProfiles array.

       This file needs to mutable, and cannot be symlinked. This is because the file stores other data,
       such as background themes, keybindingReferences, etc.
    */

    home.file = mkMerge (flatten [
      (map (v:
        let
          # The default profile does not have the `name` key
          name = if v ? name then v.name else "default";
        in [
          (mkIf ((mergedUserSettings v.userSettings) != { }) {
            "${configFilePath name}".source =
              jsonFormat.generate "vscode-user-settings"
              (mergedUserSettings v.userSettings);
          })

          (mkIf (v.userTasks != { }) {
            "${tasksFilePath name}".source =
              jsonFormat.generate "vscode-user-tasks" v.userTasks;
          })

          (mkIf (v.keybindings != [ ]) {
            "${keybindingsFilePath name}".source =
              jsonFormat.generate "vscode-keybindings"
              (map (filterAttrs (_: v: v != null)) v.keybindings);
          })

          (mkIf (v.languageSnippets != { }) (lib.mapAttrs' (language: snippet:
            lib.nameValuePair "${snippetDir name}/${language}.json" {
              source =
                jsonFormat.generate "user-snippet-${language}.json" snippet;
            }) v.languageSnippets))

          (mkIf (v.globalSnippets != { }) {
            "${snippetDir name}/global.code-snippets".source =
              jsonFormat.generate "user-snippet-global.code-snippets"
              v.globalSnippets;
          })
        ]) allProfiles)

      # We write extensions.json for all profiles, except the default profile,
      # since that is handled by code below.
      (mkIf (cfg.profiles != [ ]) (listToAttrs (map (v:
        nameValuePair "${userDir}/profiles/${v.name}/extensions.json" {
          source = "${
              extensionJsonFile v.name (extensionJson v.extensions)
            }/share/vscode/extensions/extensions.json";
        }) cfg.profiles)))

      (mkIf ((filter (v: v.extensions != [ ]) allProfiles) != [ ]) (let
        # Adapted from https://discourse.nixos.org/t/vscode-extensions-setup/1801/2
        subDir = "share/vscode/extensions";
        toPaths = ext:
          map (k: { "${extensionPath}/${k}".source = "${ext}/${subDir}/${k}"; })
          (if ext ? vscodeExtUniqueId then
            [ ext.vscodeExtUniqueId ]
          else
            builtins.attrNames (builtins.readDir (ext + "/${subDir}")));
      in if (cfg.mutableExtensionsDir && cfg.profiles == [ ]) then
        mkMerge (concatMap toPaths (flatten (map (v: v.extensions) allProfiles))
          ++ lib.optional (lib.versionAtLeast vscodeVersion "1.74.0") {
            # Whenever our immutable extensions.json changes, force VSCode to regenerate
            # extensions.json with both mutable and immutable extensions.
            "${extensionPath}/.extensions-immutable.json" = {
              text = extensionJson cfg.defaultProfile.extensions;
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
            paths = flatten (map (v: v.extensions) allProfiles) ++ lib.optional
              (lib.versionAtLeast vscodeVersion "1.74.0" && cfg.defaultProfile
                != { }) (extensionJsonFile "default"
                  (extensionJson cfg.defaultProfile.extensions));
          };
        in "${combinedExtensionsDrv}/${subDir}";
      }))
    ]);
  };
}
