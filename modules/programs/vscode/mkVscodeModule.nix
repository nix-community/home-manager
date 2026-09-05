{
  modulePath,
  name,
  packageName,
  nameShort,
  dataFolderName,
  skipVersionCheck ? false,
}:
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
  inherit (lib.hm.strings) isPathLike;

  moduleName = lib.concatStringsSep "." modulePath;

  cfg = lib.getAttrFromPath modulePath config;
  vscodeVersion = cfg.package.version or pkgs.vscode.version;

  jsonFormat = pkgs.formats.json { };
  json5 = pkgs.python3Packages.toPythonApplication pkgs.python3Packages.json5;

  userDir =
    if pkgs.stdenv.hostPlatform.isDarwin then
      "${config.home.homeDirectory}/Library/Application Support/${nameShort}/User"
    else
      "${config.xdg.configHome}/${nameShort}/User";

  argvPath = "${dataFolderName}/argv.json";

  profileDir = name: "${userDir}${optionalString (name != "default") "/profiles/${name}"}";

  configFilePath = name: "${profileDir name}/settings.json";
  tasksFilePath = name: "${profileDir name}/tasks.json";
  mcpFilePath = name: "${profileDir name}/mcp.json";
  keybindingsFilePath = name: "${profileDir name}/keybindings.json";

  snippetDir = name: "${profileDir name}/snippets";

  extensionPath = "${dataFolderName}/extensions";

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
    if isPathLike userSettings then
      userSettings
    else
      userSettings
      // lib.optionalAttrs (enableUpdateCheck == false) {
        "update.mode" = "none";
      }
      // lib.optionalAttrs (enableExtensionUpdateCheck == false) {
        "extensions.autoCheckUpdates" = false;
      };

  effectiveUserSettings =
    profile:
    mergedUserSettings profile.userSettings profile.enableUpdateCheck
      profile.enableExtensionUpdateCheck;

  declaredUserSettingsSource =
    profile:
    let
      settings = effectiveUserSettings profile;
    in
    if isPathLike settings then
      let
        settingsPath = toString settings;
      in
      if builtins.hasContext settingsPath then
        settings
      else
        builtins.path {
          path = settings;
          name = "vscode-user-settings-json5";
        }
    else
      jsonFormat.generate "vscode-user-settings" settings;

  mutableUserSettingsProfiles = lib.filterAttrs (
    _name: profile: profile.mutableUserSettings && effectiveUserSettings profile != { }
  ) cfg.profiles;

  immutableUserSettingsProfiles = lib.filterAttrs (
    _name: profile: !profile.mutableUserSettings && effectiveUserSettings profile != { }
  ) cfg.profiles;

  mutableUserSettingsOperation =
    profileName: profile:
    let
      settingsPath = configFilePath profileName;
      staticSettingsFile = declaredUserSettingsSource profile;
    in
    ''
      (
        display_path=${lib.escapeShellArg settingsPath}
        settings_path="$display_path"
        settings_was_symlink=
        if [[ -L "$display_path" ]]; then
          settings_was_symlink=1
          if ! settings_path="$(${lib.getExe' pkgs.coreutils "readlink"} -e -- "$display_path")"; then
            errorEcho "Cannot resolve ${name} settings at '$display_path'; leaving the symlink unchanged."
            exit 1
          fi
        fi
        settings_directory="$(dirname "$settings_path")"
        target_existed=
        if [[ -e "$settings_path" ]]; then
          target_existed=1
        fi

        snapshot_path=
        candidate_path=
        trap '
          [[ -z "$snapshot_path" ]] || rm -f -- "$snapshot_path"
          [[ -z "$candidate_path" ]] || rm -f -- "$candidate_path"
        ' EXIT

        dynamic='{}'
        if [[ -n "$target_existed" ]]; then
          if [[ -v DRY_RUN ]]; then
            input_path="$settings_path"
          else
            if ! snapshot_path="$(mktemp "$settings_path.snapshot.XXXXXX")"; then
              errorEcho "Creating a snapshot for ${name} settings at '$display_path' failed."
              exit 1
            fi
            if ! cp --preserve=mode -- "$settings_path" "$snapshot_path"; then
              errorEcho "Snapshotting ${name} settings at '$display_path' failed."
              exit 1
            fi
            input_path="$snapshot_path"
          fi

          if dynamic="$(${lib.getExe json5} --as-json "$input_path" 2>/dev/null)"; then
            :
          elif ${lib.getExe pkgs.gnugrep} -q '[^[:space:]]' "$input_path"; then
            errorEcho "Cannot parse ${name} settings at '$display_path' as JSON5; leaving the file unchanged."
            exit 1
          else
            grep_status=$?
            if (( grep_status > 1 )); then
              errorEcho "Cannot read ${name} settings at '$display_path'; leaving the file unchanged."
              exit 1
            fi
            dynamic='{}'
          fi
        fi

        if ! static="$(${lib.getExe json5} --as-json ${lib.escapeShellArg staticSettingsFile})"; then
          errorEcho "Cannot parse the declared ${name} settings for '$display_path' as JSON5."
          exit 1
        fi
        if ! settings="$(${lib.getExe pkgs.jq} -n '$dynamic * $static' --argjson dynamic "$dynamic" --argjson static "$static")"; then
          errorEcho "Merging ${name} settings for '$display_path' failed."
          exit 1
        fi

        verboseEcho "Merging declared ${name} settings into '$display_path'"
        if ! run mkdir -p "$settings_directory"; then
          errorEcho "Creating the directory '$settings_directory' failed."
          exit 1
        fi
        if [[ -v DRY_RUN ]]; then
          echo "Would update ${name} settings at '$display_path'"
          exit 0
        fi

        if ! candidate_path="$(mktemp "$settings_path.candidate.XXXXXX")"; then
          errorEcho "Creating a candidate for ${name} settings at '$display_path' failed."
          exit 1
        fi

        if ! printf '%s\n' "$settings" > "$candidate_path"; then
          errorEcho "Writing merged ${name} settings for '$display_path' failed."
          exit 1
        fi
        if [[ -n "$target_existed" ]] && ! chmod --reference="$snapshot_path" -- "$candidate_path"; then
          errorEcho "Copying permissions from '$display_path' failed."
          exit 1
        fi

        conflict=
        if [[ -n "$target_existed" ]]; then
          if [[ -n "$settings_was_symlink" ]]; then
            current_settings_path=
            if [[ ! -L "$display_path" ]] \
              || ! current_settings_path="$(${lib.getExe' pkgs.coreutils "readlink"} -e -- "$display_path")" \
              || [[ "$current_settings_path" != "$settings_path" ]]; then
              conflict=1
            fi
          elif [[ -L "$display_path" ]]; then
            conflict=1
          fi

          if ! cmp -s -- "$snapshot_path" "$settings_path"; then
            conflict=1
          fi
        elif [[ -e "$display_path" || -L "$display_path" ]]; then
          conflict=1
        fi

        if [[ -n "$conflict" ]]; then
          errorEcho "${name} settings at '$display_path' changed during activation; keeping the newer file."
          exit 1
        fi

        if ! mv -f -- "$candidate_path" "$settings_path"; then
          errorEcho "Replacing ${name} settings at '$display_path' failed."
          exit 1
        fi
        candidate_path=
      ) || exit 1
    '';

  immutableUserSettingsOperation =
    profileName: profile:
    let
      settingsPath = configFilePath profileName;
      settingsSource = declaredUserSettingsSource profile;
    in
    ''
      if [[ -f ${lib.escapeShellArg settingsPath} && ! -L ${lib.escapeShellArg settingsPath} ]] \
        && cmp -s -- ${lib.escapeShellArg settingsSource} ${lib.escapeShellArg settingsPath}; then
        run rm -- ${lib.escapeShellArg settingsPath}
      fi
    '';

  transformMcpServerForVscode = name: server: {
    inherit name;
    value = lib.hm.mcp.transformMcpServer {
      inherit server;
      extraTransforms = [
        lib.hm.mcp.addType
        (lib.hm.mcp.wrapEnvFilesCommand { inherit pkgs name; })
      ];
    };
  };

  profileType = types.submodule {
    options = {
      mutableUserSettings = lib.mkEnableOption "mutable user settings for ${name}";

      userSettings = mkOption {
        type = types.either types.path jsonFormat.type;
        default = { };
        example = {
          "files.autoSave" = "off";
          "[nix]"."editor.tabSize" = 2;
        };
        description = ''
          Configuration written to ${name}'s
          {file}`settings.json`.
          This can be a JSON object or a path to a custom JSON file.
        '';
      };

      userTasks = mkOption {
        type = types.either types.path jsonFormat.type;
        default = { };
        example = {
          version = "2.0.0";
          tasks = [
            {
              type = "shell";
              label = "Hello task";
              command = "hello";
            }
          ];
        };
        description = ''
          Configuration written to ${name}'s
          {file}`tasks.json`.
          This can be a JSON object or a path to a custom JSON file.
        '';
      };

      enableMcpIntegration = mkOption {
        type = lib.types.bool;
        default = false;
        description = ''
          Whether to integrate the MCP servers config from
          {option}`programs.mcp.servers` into
          {option}`${moduleName}.profiles.<name>.userMcp`.

          Note: Settings defined in {option}`programs.mcp.servers` are merged
          with {option}`${moduleName}.profiles.<name>.userMcp`, with ${name}
          settings taking precedence.
        '';
      };

      userMcp = mkOption {
        type = types.either types.path jsonFormat.type;
        default = { };
        example.servers.Github.url = "https://api.githubcopilot.com/mcp/";
        description = ''
          Configuration written to ${name}'s
          {file}`mcp.json`.
          This can be a JSON object or a path to a custom JSON file.
        '';
      };

      keybindings = mkOption {
        type = types.either types.path (
          types.listOf (
            types.submodule {
              freeformType = jsonFormat.type;
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
        example = [
          {
            key = "ctrl+c";
            command = "editor.action.clipboardCopyAction";
            when = "textInputFocus";
          }
        ];
        description = ''
          Keybindings written to ${name}'s
          {file}`keybindings.json`.
          This can be a JSON object or a path to a custom JSON file.
        '';
      };

      extensions = mkOption {
        type = types.listOf types.package;
        default = [ ];
        example = literalExpression "[ pkgs.vscode-extensions.bbenoist.nix ]";
        description = ''
          The extensions ${name} should be started with.
        '';
      };

      languageSnippets = mkOption {
        inherit (jsonFormat) type;
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
        inherit (jsonFormat) type;
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
  defaultProfile = cfg.profiles.default or { };
  allProfilesExceptDefault = removeAttrs cfg.profiles [ "default" ];
in
{
  options = lib.setAttrByPath modulePath {
    enable = lib.mkEnableOption name;

    package = lib.mkPackageOption pkgs packageName {
      nullable = true;
      extraDescription = "Version of ${name} to install.";
    };

    mutableExtensionsDir = mkOption {
      type = types.bool;
      default = allProfilesExceptDefault == { };
      defaultText = lib.literalExpression "(removeAttrs config.${moduleName}.profiles [ \"default\" ]) == { }";
      example = false;
      description = ''
        Whether extensions can be installed or updated manually
        or by ${name}. Mutually exclusive to
        ${moduleName}.profiles.
      '';
    };

    argvSettings = mkOption {
      type = types.either types.path jsonFormat.type;
      default = { };
      example = {
        enable-crash-reporter = false;
      };
      description = ''
        Configuration written to ${name}'s
        {file}`argv.json`.
        This can be a JSON object or a path to a custom JSON file.
      '';
    };

    profiles = mkOption {
      type = types.attrsOf profileType;
      default = { };
      description = ''
        A list of all ${name} profiles. Mutually exclusive
        to ${moduleName}.mutableExtensionsDir
      '';
    };
  };

  config = mkIf cfg.enable {
    warnings = [
      (mkIf (
        allProfilesExceptDefault != { } && cfg.mutableExtensionsDir
      ) "${moduleName}.mutableExtensionsDir can be used only if no profiles apart from default are set.")
      (mkIf
        (
          (lib.filterAttrs (
            _n: v:
            (v ? enableExtensionUpdateCheck || v ? enableUpdateCheck)
            && (v.enableExtensionUpdateCheck != null || v.enableUpdateCheck != null)
          ) allProfilesExceptDefault) != { }
        )
        "The option ${moduleName}.profiles.*.enableExtensionUpdateCheck and option ${moduleName}.profiles.*.enableUpdateCheck is invalid for all profiles except default."
      )
    ];

    home.packages = lib.mkIf (cfg.package != null) [ cfg.package ];

    # The file `${userDir}/globalStorage/storage.json` needs to be writable by VSCode,
    # since it contains other data, such as theme backgrounds, recently opened folders, etc.

    # A caveat of adding profiles this way is, VSCode has to be closed
    # when this file is being written, since the file is loaded into RAM
    # and overwritten on closing VSCode.
    home.activation = {
      "${lib.last modulePath}Profiles" = lib.hm.dag.entryAfter [ "writeBoundary" ] (
        let
          modifyGlobalStorage = pkgs.writeShellScript "${lib.last modulePath}-global-storage-modify" ''
            PATH=${lib.makeBinPath [ pkgs.jq ]}''${PATH:+:}$PATH
            file="${userDir}/globalStorage/storage.json"
            file_write=""
            profiles=(${lib.escapeShellArgs (flatten (mapAttrsToList (n: _v: n) allProfilesExceptDefault))})

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
    }
    // lib.optionalAttrs (mutableUserSettingsProfiles != { }) {
      "${lib.last modulePath}MutableUserSettings" = lib.hm.dag.entryAfter [ "linkGeneration" ] (
        lib.concatStrings (lib.mapAttrsToList mutableUserSettingsOperation mutableUserSettingsProfiles)
      );
    }
    // lib.optionalAttrs (immutableUserSettingsProfiles != { }) {
      "${lib.last modulePath}ImmutableUserSettings" =
        lib.hm.dag.entryBetween
          [ "linkGeneration" ]
          [
            "writeBoundary"
          ]
          (
            lib.concatStrings (lib.mapAttrsToList immutableUserSettingsOperation immutableUserSettingsProfiles)
          );
    };

    home.file = lib.mkMerge (flatten [
      (mkIf (cfg.argvSettings != { }) {
        "${argvPath}".source =
          if isPathLike cfg.argvSettings then
            cfg.argvSettings
          else
            jsonFormat.generate "vscode-argv" cfg.argvSettings;
      })

      (mapAttrsToList (n: v: [
        (
          let
            merged = effectiveUserSettings v;
          in
          mkIf (!v.mutableUserSettings && merged != { }) {
            "${configFilePath n}".source = declaredUserSettingsSource v;
          }
        )

        (mkIf (v.userTasks != { }) {
          "${tasksFilePath n}".source =
            if isPathLike v.userTasks then v.userTasks else jsonFormat.generate "vscode-user-tasks" v.userTasks;
        })

        (mkIf
          (
            v.userMcp != { }
            || (v.enableMcpIntegration && config.programs.mcp.enable && config.programs.mcp.servers != { })
          )
          {
            "${mcpFilePath n}".source =
              if isPathLike v.userMcp then
                v.userMcp
              else
                let
                  transformedMcpServers =
                    if v.enableMcpIntegration && config.programs.mcp.enable && config.programs.mcp.servers != { } then
                      lib.listToAttrs (lib.mapAttrsToList transformMcpServerForVscode config.programs.mcp.servers)
                    else
                      { };
                  # Merge MCP servers: transformed servers + user servers, with user servers taking precedence
                  mergedServers = transformedMcpServers // (v.userMcp.servers or { });
                  # Merge all MCP config
                  mergedMcpConfig =
                    v.userMcp // (lib.optionalAttrs (mergedServers != { }) { servers = mergedServers; });
                in
                jsonFormat.generate "vscode-user-mcp" mergedMcpConfig;
          }
        )

        (mkIf (v.keybindings != [ ]) {
          "${keybindingsFilePath n}".source =
            if isPathLike v.keybindings then
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
          lib.nameValuePair "${profileDir n}/extensions.json" {
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
            lib.concatMap toPaths (flatten (mapAttrsToList (_n: v: v.extensions) cfg.profiles))
            ++
              lib.optional
                (
                  (lib.versionAtLeast vscodeVersion "1.74.0" || skipVersionCheck)
                  && defaultProfile != { }
                  && cfg.package != null
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
                    (flatten (mapAttrsToList (_n: v: v.extensions) cfg.profiles))
                    ++ lib.optional (
                      (lib.versionAtLeast vscodeVersion "1.74.0" || skipVersionCheck) && defaultProfile != { }
                    ) (extensionJsonFile "default" (extensionJson defaultProfile.extensions));
                };
              in
              "${combinedExtensionsDrv}/${subDir}";
          }
      ))
    ]);
  };
}
