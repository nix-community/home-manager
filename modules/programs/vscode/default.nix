{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib)
    flatten
    literalExpression
    mapAttrsToList
    mkOption
    mkIf
    optionalString
    types
    ;

  cfg = config.programs.vscode;

  vscodePname = cfg.package.pname;
  vscodeVersion = cfg.package.version;

  jsonFormat = pkgs.formats.json { };

  productInfoPath =
    if
      lib.pathExists "${cfg.package}/Applications/${
        cfg.package.passthru.longName or "Code"
      }.app/Contents/Resources/app/product.json"
    then
      "${cfg.package}/Applications/${
        cfg.package.passthru.longName or "Code"
      }.app/Contents/Resources/app/product.json"
    else if lib.pathExists "${cfg.package}/lib/vscode/resources/app/product.json" then
      # Visual Studio Code, VSCodium, Windsurf, Cursor
      "${cfg.package}/lib/vscode/resources/app/product.json"
    else
      # OpenVSCode Server
      "${cfg.package}/product.json";

  productInfo = lib.importJSON productInfoPath;

  # Use preset names for known products to avoid IFD loading it from product.json
  knownProducts = {
    cursor = {
      dataFolderName = ".cursor";
      nameShort = "Cursor";
    };
    kiro = {
      dataFolderName = ".kiro";
      nameShort = "Kiro";
    };
    openvscode-server = {
      dataFolderName = ".openvscode-server";
      nameShort = "OpenVSCode Server";
    };
    vscode = {
      dataFolderName = ".vscode";
      nameShort = "Code";
    };
    vscode-insiders = {
      dataFolderName = ".vscode-insiders";
      nameShort = "Code - Insiders";
    };
    vscodium = {
      dataFolderName = ".vscode-oss";
      nameShort = "VSCodium";
    };
    windsurf = {
      dataFolderName = ".windsurf";
      nameShort = "Windsurf";
    };
  };

  configDir = cfg.nameShort;
  extensionDir = cfg.dataFolderName;

  userDir =
    if pkgs.stdenv.hostPlatform.isDarwin then
      "${config.home.homeDirectory}/Library/Application Support/${configDir}/User"
    else
      "${config.xdg.configHome}/${configDir}/User";

  configFilePath =
    name: "${userDir}/${optionalString (name != "default") "profiles/${name}/"}settings.json";
  tasksFilePath =
    name: "${userDir}/${optionalString (name != "default") "profiles/${name}/"}tasks.json";
  mcpFilePath = name: "${userDir}/${optionalString (name != "default") "profiles/${name}/"}mcp.json";
  keybindingsFilePath =
    name: "${userDir}/${optionalString (name != "default") "profiles/${name}/"}keybindings.json";

  snippetDir = name: "${userDir}/${optionalString (name != "default") "profiles/${name}/"}snippets";

  extensionPath = "${extensionDir}/extensions";

  extensionJson = ext: pkgs.vscode-utils.toExtensionJson ext;
  extensionJsonFile =
    name: text:
    pkgs.writeTextFile {
      inherit text;
      name = "extensions-json-${name}";
      destination = "/share/vscode/extensions/extensions.json";
    };

  mergedUserSettings =
    userSettings: enableUpdateCheck: enableExtensionUpdateCheck:
    userSettings
    // lib.optionalAttrs (enableUpdateCheck == false) {
      "update.mode" = "none";
    }
    // lib.optionalAttrs (enableExtensionUpdateCheck == false) {
      "extensions.autoCheckUpdates" = false;
    };

  isPath = p: builtins.isPath p || lib.isStorePath p;

  profileType = types.submodule {
    options = {
      userSettings = mkOption {
        type = types.either types.path jsonFormat.type;
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
          This can be a JSON object or a path to a custom JSON file.
        '';
      };

      userTasks = mkOption {
        type = types.either types.path jsonFormat.type;
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
          This can be a JSON object or a path to a custom JSON file.
        '';
      };

      userMcp = mkOption {
        type = types.either types.path jsonFormat.type;
        default = { };
        example = literalExpression ''
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

      keybindings = mkOption {
        type = types.either types.path (
          types.listOf (
            types.submodule {
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
          This can be a JSON object or a path to a custom JSON file.
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
in
{
  imports = [
    ./haskell.nix
    (lib.mkChangedOptionModule
      [
        "programs"
        "vscode"
        "immutableExtensionsDir"
      ]
      [ "programs" "vscode" "mutableExtensionsDir" ]
      (config: !config.programs.vscode.immutableExtensionsDir)
    )
  ]
  ++
    map
      (
        v:
        lib.mkRenamedOptionModule
          [ "programs" "vscode" v ]
          [
            "programs"
            "vscode"
            "profiles"
            "default"
            v
          ]
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

  options.programs.vscode = {
    enable = lib.mkEnableOption "Visual Studio Code";

    package = lib.mkPackageOption pkgs "vscode" {
      example = "pkgs.vscodium";
      extraDescription = "Version of Visual Studio Code to install.";
    };

    mutableExtensionsDir = mkOption {
      type = types.bool;
      default = allProfilesExceptDefault == { };
      defaultText = lib.literalExpression "(removeAttrs config.programs.vscode.profiles [ \"default\" ]) == { }";
      example = false;
      description = ''
        Whether extensions can be installed or updated manually
        or by Visual Studio Code. Mutually exclusive to
        programs.vscode.profiles.
      '';
    };

    nameShort = mkOption {
      type = types.str;
      default = knownProducts.${vscodePname}.nameShort or productInfo.nameShort;
      defaultText = "(derived from product.json)";
      example = "MyCoolVSCodeFork";
      description = ''
        Override for package "short name", used for generating configuration.

        This should match the `shortName` field in the package's product.json. If `null`, then searches common locations for a product.json and uses the value from there.
      '';
    };

    dataFolderName = mkOption {
      type = types.str;
      default = knownProducts.${vscodePname}.dataFolderName or productInfo.dataFolderName;
      defaultText = "(derived from product.json)";
      example = ".cool-vscode";
      description = ''
        Override for extensions directory.

        This should match the `dataFolderName` field in the package's product.json. If `null`, then searches common locations for a product.json and uses the value from there.
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
        "programs.vscode.mutableExtensionsDir can be used only if no profiles apart from default are set."
      )
      (mkIf
        (
          (lib.filterAttrs (
            n: v:
            (v ? enableExtensionUpdateCheck || v ? enableUpdateCheck)
            && (v.enableExtensionUpdateCheck != null || v.enableUpdateCheck != null)
          ) allProfilesExceptDefault) != { }
        )
        "The option programs.vscode.profiles.*.enableExtensionUpdateCheck and option programs.vscode.profiles.*.enableUpdateCheck is invalid for all profiles except default."
      )
    ];

    home.packages = [ cfg.package ];

    # The file `${userDir}/globalStorage/storage.json` needs to be writable by VSCode,
    # since it contains other data, such as theme backgrounds, recently opened folders, etc.

    # A caveat of adding profiles this way is, VSCode has to be closed
    # when this file is being written, since the file is loaded into RAM
    # and overwritten on closing VSCode.
    home.activation.vscodeProfiles = lib.hm.dag.entryAfter [ "writeBoundary" ] (
      let
        modifyGlobalStorage = pkgs.writeShellScript "vscode-global-storage-modify" ''
          PATH=${lib.makeBinPath [ pkgs.jq ]}''${PATH:+:}$PATH
          file="${userDir}/globalStorage/storage.json"
          file_write=""
          profiles=(${lib.escapeShellArgs (flatten (mapAttrsToList (n: v: n) allProfilesExceptDefault))})

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

    home.file = lib.mkMerge (flatten [
      (mapAttrsToList (n: v: [
        (mkIf ((mergedUserSettings v.userSettings v.enableUpdateCheck v.enableExtensionUpdateCheck) != { })
          {
            "${configFilePath n}".source =
              if isPath v.userSettings then
                v.userSettings
              else
                jsonFormat.generate "vscode-user-settings" (
                  mergedUserSettings v.userSettings v.enableUpdateCheck v.enableExtensionUpdateCheck
                );
          }
        )

        (mkIf (v.userTasks != { }) {
          "${tasksFilePath n}".source =
            if isPath v.userTasks then v.userTasks else jsonFormat.generate "vscode-user-tasks" v.userTasks;
        })

        (mkIf (v.userMcp != { }) {
          "${mcpFilePath n}".source =
            if isPath v.userMcp then v.userMcp else jsonFormat.generate "vscode-user-mcp" v.userMcp;
        })

        (mkIf (v.keybindings != [ ]) {
          "${keybindingsFilePath n}".source =
            if isPath v.keybindings then
              v.keybindings
            else
              jsonFormat.generate "vscode-keybindings" (map (lib.filterAttrs (_: v: v != null)) v.keybindings);
        })

        (mkIf (v.languageSnippets != { }) (
          lib.mapAttrs' (
            language: snippet:
            lib.nameValuePair "${snippetDir n}/${language}.json" {
              source = jsonFormat.generate "user-snippet-${language}.json" snippet;
            }
          ) v.languageSnippets
        ))

        (mkIf (v.globalSnippets != { }) {
          "${snippetDir n}/global.code-snippets".source =
            jsonFormat.generate "user-snippet-global.code-snippets" v.globalSnippets;
        })
      ]) cfg.profiles)

      # We write extensions.json for all profiles, except the default profile,
      # since that is handled by code below.
      (mkIf (allProfilesExceptDefault != { }) (
        lib.mapAttrs' (
          n: v:
          lib.nameValuePair "${userDir}/profiles/${n}/extensions.json" {
            source = "${extensionJsonFile n (extensionJson v.extensions)}/share/vscode/extensions/extensions.json";
          }
        ) allProfilesExceptDefault
      ))

      (mkIf (cfg.profiles != { }) (
        let
          # Adapted from https://discourse.nixos.org/t/vscode-extensions-setup/1801/2
          subDir = "share/vscode/extensions";
          toPaths =
            ext:
            map (k: { "${extensionPath}/${k}".source = "${ext}/${subDir}/${k}"; }) (
              if ext ? vscodeExtUniqueId then
                [ ext.vscodeExtUniqueId ]
              else
                builtins.attrNames (builtins.readDir (ext + "/${subDir}"))
            );
        in
        if (cfg.mutableExtensionsDir && allProfilesExceptDefault == { }) then
          # Mutable extensions dir can only occur when only default profile is set.
          # Force regenerating extensions.json using the below method,
          # causes VSCode to create the extensions.json with all the extensions
          # in the extension directory, which includes extensions from other profiles.
          lib.mkMerge (
            lib.concatMap toPaths (flatten (mapAttrsToList (n: v: v.extensions) cfg.profiles))
            ++
              lib.optional
                (
                  (
                    lib.versionAtLeast vscodeVersion "1.74.0"
                    || builtins.elem vscodePname [
                      "cursor"
                      "windsurf"
                    ]
                  )
                  && defaultProfile != { }
                )
                {
                  # Whenever our immutable extensions.json changes, force VSCode to regenerate
                  # extensions.json with both mutable and immutable extensions.
                  "${extensionPath}/.extensions-immutable.json" = {
                    text = extensionJson defaultProfile.extensions;
                    onChange = ''
                      run rm $VERBOSE_ARG -f ${extensionPath}/{extensions.json,.init-default-profile-extensions}
                      verboseEcho "Regenerating VSCode extensions.json"
                      run ${lib.getExe cfg.package} --list-extensions > /dev/null
                    '';
                  };
                }
          )
        else
          {
            "${extensionPath}".source =
              let
                combinedExtensionsDrv = pkgs.buildEnv {
                  name = "vscode-extensions";
                  paths =
                    (flatten (mapAttrsToList (n: v: v.extensions) cfg.profiles))
                    ++ lib.optional (
                      (
                        lib.versionAtLeast vscodeVersion "1.74.0"
                        || builtins.elem vscodePname [
                          "cursor"
                          "windsurf"
                        ]
                      )
                      && defaultProfile != { }
                    ) (extensionJsonFile "default" (extensionJson defaultProfile.extensions));
                };
              in
              "${combinedExtensionsDrv}/${subDir}";
          }
      ))
    ]);
  };
}
