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
    mapAttrsToList
    mkOption
    mkIf
    optionalString
    types
    ;
  inherit (lib.hm.strings) isPathLike;

  appName = name; # for clearer variable name below
  moduleName = lib.concatStringsSep "." modulePath;

  cfg = lib.getAttrFromPath modulePath config;
  vscodeVersion = cfg.package.version or pkgs.vscode.version;

  jsonFormat = pkgs.formats.json { };

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

  profileType = types.submoduleWith {
    class = "homeManager.vscodeProfile";
    modules = [
      ./profiles/default.nix
      ({ name, ... }: {
        config._module.args = {
          # intended for use in documentation / description strings
          inherit appName pkgs;
          moduleName = "${moduleName}.profiles.${name}";
        };
      })
    ];
    specialArgs = {
      inherit lib; # provide with lib.hm
    };
  };
  defaultProfile = cfg.profiles.default or { };
  allProfilesExceptDefault = removeAttrs cfg.profiles [ "default" ];
in
{
  options = lib.setAttrByPath modulePath {
    enable = lib.mkEnableOption appName;

    package = lib.mkPackageOption pkgs packageName {
      nullable = true;
      extraDescription = "Version of ${appName} to install.";
    };

    mutableExtensionsDir = mkOption {
      type = types.bool;
      default = allProfilesExceptDefault == { };
      defaultText = lib.literalExpression "(removeAttrs config.${moduleName}.profiles [ \"default\" ]) == { }";
      example = false;
      description = ''
        Whether extensions can be installed or updated manually
        or by ${appName}. Mutually exclusive to
        ${moduleName}.profiles.
      '';
    };

    argvSettings = mkOption {
      type = with types; either path json;
      default = { };
      example = {
        enable-crash-reporter = false;
      };
      description = ''
        Configuration written to ${appName}'s
        {file}`argv.json`.
        This can be a JSON object or a path to a custom JSON file.
      '';
    };

    profiles = mkOption {
      type = types.attrsOf profileType;
      default = { };
      description = ''
        A list of all ${appName} profiles. Mutually exclusive
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
            merged = mergedUserSettings v.userSettings v.enableUpdateCheck v.enableExtensionUpdateCheck;
          in
          mkIf (merged != { }) {
            "${configFilePath n}".source =
              if isPathLike merged then merged else jsonFormat.generate "vscode-user-settings" merged;
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
