{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib)
    literalExpression
    mkIf
    mkOption
    types
    ;

  cfg = config.programs.obs-studio;
  iniFormat = pkgs.formats.ini { };
  jsonFormat = pkgs.formats.json { };
  pluginPackages = lib.filterAttrs (_: value: lib.isDerivation value) pkgs.obs-studio-plugins;
  pluginNames = lib.attrNames pluginPackages;

  fileType = types.submodule (
    { config, ... }:
    {
      options = {
        source = mkOption {
          type = types.nullOr types.path;
          default = null;
          description = "Path to the file to install.";
        };

        text = mkOption {
          type = types.nullOr types.lines;
          default = null;
          description = "Text content to install.";
        };
      };

      config.source = mkIf (config.text != null) (
        lib.mkDefault (pkgs.writeText "obs-studio-extra-file" config.text)
      );
    }
  );

  safePathComponent =
    value: value != "" && value != "." && value != ".." && !(lib.hasInfix "/" value);
  safeRelativePath =
    path:
    path != ""
    && !(lib.hasPrefix "/" path)
    && lib.all (part: part != "" && part != "." && part != "..") (lib.splitString "/" path);

  profileGeneratedPaths =
    profile:
    lib.optionals (profile.settings != { }) [ "basic.ini" ]
    ++ lib.optionals (profile.streamEncoder != { }) [ "streamEncoder.json" ]
    ++ lib.optionals (profile.recordEncoder != { }) [ "recordEncoder.json" ];

  listIntersection = left: right: lib.filter (value: builtins.elem value right) left;

  integrationConfigPaths = lib.concatMapAttrs (
    pluginName: integration:
    lib.genAttrs (map (path: "${pluginName}/${path}") (lib.attrNames integration.extraConfigFiles)) (
      _: true
    )
  ) cfg.integrations;

  mkGeneratedFile = origin: kind: source: {
    inherit kind origin source;
  };

  generatedFileEntries =
    lib.optionalAttrs (cfg.settings.global != { }) {
      "global.ini" = mkGeneratedFile "settings.global" "ini" (
        iniFormat.generate "obs-studio-global.ini" cfg.settings.global
      );
    }
    // lib.optionalAttrs (cfg.settings.user != { }) {
      "user.ini" = mkGeneratedFile "settings.user" "ini" (
        iniFormat.generate "obs-studio-user.ini" cfg.settings.user
      );
    }
    // lib.concatMapAttrs (
      name: profile:
      lib.optionalAttrs (profile.settings != { }) {
        "basic/profiles/${name}/basic.ini" = mkGeneratedFile "profiles.${name}.settings" "ini" (
          iniFormat.generate "obs-studio-profile-${name}.ini" profile.settings
        );
      }
      // lib.optionalAttrs (profile.streamEncoder != { }) {
        "basic/profiles/${name}/streamEncoder.json" =
          mkGeneratedFile "profiles.${name}.streamEncoder" "json"
            (jsonFormat.generate "obs-studio-stream-encoder-${name}.json" profile.streamEncoder);
      }
      // lib.optionalAttrs (profile.recordEncoder != { }) {
        "basic/profiles/${name}/recordEncoder.json" =
          mkGeneratedFile "profiles.${name}.recordEncoder" "json"
            (jsonFormat.generate "obs-studio-record-encoder-${name}.json" profile.recordEncoder);
      }
      // lib.mapAttrs' (
        path: file:
        lib.nameValuePair "basic/profiles/${name}/${path}" (
          mkGeneratedFile "profiles.${name}.extraFiles.${path}" "raw" file.source
        )
      ) (lib.filterAttrs (_: file: file.source != null) profile.extraFiles)
    ) cfg.profiles
    // lib.mapAttrs' (
      name: collection:
      lib.nameValuePair "basic/scenes/${name}.json" (
        mkGeneratedFile "sceneCollections.${name}" "json" (
          jsonFormat.generate "obs-studio-scene-collection-${name}.json" collection
        )
      )
    ) (lib.filterAttrs (_: collection: collection != { }) cfg.sceneCollections)
    // lib.mapAttrs' (
      path: file:
      lib.nameValuePair "plugin_config/${path}" (
        mkGeneratedFile "extraConfigFiles.${path}" "raw" file.source
      )
    ) (lib.filterAttrs (_: file: file.source != null) cfg.extraConfigFiles)
    // lib.concatMapAttrs (
      pluginName: integration:
      lib.mapAttrs' (
        path: file:
        lib.nameValuePair "plugin_config/${pluginName}/${path}" (
          mkGeneratedFile "integrations.${pluginName}.extraConfigFiles.${path}" "raw" file.source
        )
      ) (lib.filterAttrs (_: file: file.source != null) integration.extraConfigFiles)
    ) cfg.integrations;

  generatedFiles = lib.mapAttrs (_: file: file.source) generatedFileEntries;
  configRoot = "${config.xdg.configHome}/obs-studio";
  manifestTarget = "${config.xdg.stateHome}/home-manager/obs-studio/manifest.json";

  generatedManifest = jsonFormat.generate "obs-studio-generated-files-manifest.json" {
    version = 1;
    module = "programs.obs-studio";
    files = lib.mapAttrsToList (path: file: {
      inherit path;
      source = toString file.source;
      target = "${configRoot}/${path}";
      sha256 = builtins.hashFile "sha256" file.source;
      inherit (file) kind origin;
    }) generatedFileEntries;
  };

  prepareRemovedFiles = ''
    configRoot=${lib.escapeShellArg configRoot}
    manifest=${lib.escapeShellArg manifestTarget}
    stalePaths=

    if [[ -e "$manifest" ]]; then
      stalePaths="$(${pkgs.coreutils}/bin/mktemp)"
      if ! ${lib.getExe pkgs.jq} -j --slurpfile current ${lib.escapeShellArg generatedManifest} '
        if .version != 1 or .module != "programs.obs-studio" or (.files | type) != "array" then
          error("invalid OBS Studio generated-files manifest")
        elif (
          all(.files[]; (.path | type) == "string" and (.path | contains("\u0000") | not))
          | not
        ) then
          error("invalid OBS Studio generated-files manifest path")
        else
          [$current[0].files[].path] as $currentPaths
          | .files[]
          | select(.path as $path | ($currentPaths | index($path) | not))
          | .path, "\u0000"
        end
      ' "$manifest" > "$stalePaths"; then
        rm -f "$stalePaths"
        echo "Cannot reconcile the previous OBS Studio generated-files manifest." >&2
        exit 1
      fi
    fi
  '';

  installGeneratedFiles = ''
    prepareObsStudioParent() {
      local target="$1"
      local parent
      parent="$(dirname "$target")"

      if [[ -v DRY_RUN ]]; then
        run mkdir -p "$parent"
        return
      fi

      local canonicalConfigRoot
      canonicalConfigRoot="$(${pkgs.coreutils}/bin/realpath -e -- "$configRoot")"
      local existingParent="$parent"
      while [[ ! -e "$existingParent" && ! -L "$existingParent" ]]; do
        existingParent="$(dirname "$existingParent")"
      done

      local canonicalExistingParent
      canonicalExistingParent="$(${pkgs.coreutils}/bin/realpath -e -- "$existingParent" 2>/dev/null || true)"
      case "$canonicalExistingParent" in
        "$canonicalConfigRoot" | "$canonicalConfigRoot"/*) ;;
        *)
          echo "Refusing to write OBS Studio configuration outside $configRoot" >&2
          return 1
          ;;
      esac

      run mkdir -p "$parent"
      local canonicalParent
      canonicalParent="$(${pkgs.coreutils}/bin/realpath -e -- "$parent")"
      case "$canonicalParent" in
        "$canonicalConfigRoot" | "$canonicalConfigRoot"/*) ;;
        *)
          echo "Refusing to write OBS Studio configuration outside $configRoot" >&2
          return 1
          ;;
      esac
    }

    run mkdir -p "$configRoot"
    ${lib.concatStringsSep "\n" (
      lib.mapAttrsToList (
        path: source:
        let
          target = "${configRoot}/${path}";
        in
        ''
          target=${lib.escapeShellArg target}
          tmp="$target.tmp.$$"
          prepareObsStudioParent "$target" || exit 1
          if [[ ! -v DRY_RUN && -d "$target" ]]; then
            echo "Cannot replace OBS Studio directory with generated file: $target" >&2
            exit 1
          fi
          run install -m 0644 ${lib.escapeShellArg source} "$tmp"
          run mv "$tmp" "$target"
        ''
      ) generatedFiles
    )}
  '';

  removeStaleGeneratedFiles = ''
    if [[ -n "$stalePaths" ]]; then
      canonicalConfigRoot="$(${pkgs.coreutils}/bin/realpath -e -- "$configRoot" 2>/dev/null || true)"
      while IFS= read -r -d "" path; do
        safe=true
        case "$path" in
          "" | /*) safe=false ;;
        esac
        case "/$path/" in
          *"//"* | *"/./"* | *"/../"*) safe=false ;;
        esac

        if [[ "$safe" == false ]]; then
          printf 'Ignoring unsafe path in the previous OBS Studio manifest: %q\n' "$path" >&2
          continue
        fi

        target="$configRoot/$path"
        parent="$(dirname "$target")"
        canonicalParent="$(${pkgs.coreutils}/bin/realpath -e -- "$parent" 2>/dev/null || true)"
        contained=false
        if [[ -n "$canonicalConfigRoot" ]]; then
          case "$canonicalParent" in
            "$canonicalConfigRoot" | "$canonicalConfigRoot"/*)
              run rm -f -- "$target"
              contained=true
              ;;
            *) printf 'Ignoring path outside the OBS Studio config directory: %q\n' "$path" >&2 ;;
          esac
        fi

        while [[ "$contained" == true && "$parent" != "$configRoot" ]]; do
          canonicalParent="$(${pkgs.coreutils}/bin/realpath -e -- "$parent" 2>/dev/null || true)"
          case "$canonicalParent" in
            "$canonicalConfigRoot" | "$canonicalConfigRoot"/*) ;;
            *) break ;;
          esac
          if ! run --silence ${pkgs.coreutils}/bin/rmdir -- "$parent"; then
            break
          fi
          parent="$(dirname "$parent")"
        done
      done < "$stalePaths"
      rm -f "$stalePaths"
    fi
  '';

  installGeneratedManifest = ''
    target=${lib.escapeShellArg manifestTarget}
    tmp="$target.tmp.$$"
    run mkdir -p "$(dirname "$target")"
    run install -m 0644 ${lib.escapeShellArg generatedManifest} "$tmp"
    run mv "$tmp" "$target"
  '';

  enabledIntegrations = lib.filter (integration: integration.enable) (
    lib.attrValues cfg.integrations
  );

  enabledIntegrationPackages = map (integration: integration.package) (
    lib.filter (integration: integration.package != null) enabledIntegrations
  );

  integrationModule =
    {
      name,
      ...
    }:
    {
      options = {
        enable = mkOption {
          type = types.bool;
          default = false;
          description = "Whether to install the ${name} OBS Studio plugin from nixpkgs.";
        };

        package = mkOption {
          type = types.nullOr types.package;
          default = if builtins.hasAttr name pluginPackages then pluginPackages.${name} else null;
          defaultText = literalExpression "pkgs.obs-studio-plugins.<name>";
          description = "Plugin package to use for this integration.";
        };

        extraConfigFiles = mkOption {
          type = types.attrsOf fileType;
          default = { };
          description = ''
            Additional writable files installed relative to
            {file}`$XDG_CONFIG_HOME/obs-studio/plugin_config/${name}`.
          '';
        };
      };
    };
in
{
  meta.maintainers = [ ];

  options = {
    programs.obs-studio = {
      enable = lib.mkEnableOption "obs-studio";

      package = lib.mkPackageOption pkgs "obs-studio" { };

      finalPackage = lib.mkOption {
        type = lib.types.package;
        visible = false;
        readOnly = true;
        description = "Resulting customized OBS Studio package.";
      };

      plugins = lib.mkOption {
        default = [ ];
        example = lib.literalExpression "[ pkgs.obs-studio-plugins.wlrobs ]";
        description = "Optional OBS plugins.";
        type = lib.types.listOf lib.types.package;
      };

      integrations = mkOption {
        type = types.attrsOf (types.submodule integrationModule);
        default = { };
        example = literalExpression ''
          {
            wlrobs.enable = true;
            obs-websocket = {
              enable = true;
              extraConfigFiles."config.json".text = '''
                {"server_port":4455}
              ''';
            };
          }
        '';
        description = ''
          Named integrations for OBS Studio plugins available in
          `pkgs.obs-studio-plugins`. Supported names in the current nixpkgs are:
          ${lib.concatStringsSep ", " pluginNames}.
        '';
      };

      settings = {
        global = mkOption {
          inherit (iniFormat) type;
          default = { };
          example = literalExpression ''
            {
              General = {
                MaxLogs = 10;
                ProcessPriority = "Normal";
              };
            }
          '';
          description = "Configuration written to {file}`$XDG_CONFIG_HOME/obs-studio/global.ini`.";
        };

        user = mkOption {
          inherit (iniFormat) type;
          default = { };
          description = "Configuration written to {file}`$XDG_CONFIG_HOME/obs-studio/user.ini`.";
        };
      };

      profiles = mkOption {
        type = types.attrsOf (
          types.submodule {
            options = {
              settings = mkOption {
                inherit (iniFormat) type;
                default = { };
                description = "Configuration written to the profile's {file}`basic.ini`.";
              };

              streamEncoder = mkOption {
                inherit (jsonFormat) type;
                default = { };
                description = "Configuration written to the profile's {file}`streamEncoder.json`.";
              };

              recordEncoder = mkOption {
                inherit (jsonFormat) type;
                default = { };
                description = "Configuration written to the profile's {file}`recordEncoder.json`.";
              };

              extraFiles = mkOption {
                type = types.attrsOf fileType;
                default = { };
                description = "Additional writable files installed relative to the OBS profile directory.";
              };
            };
          }
        );
        default = { };
        description = "Declarative OBS profiles.";
      };

      sceneCollections = mkOption {
        type = types.attrsOf jsonFormat.type;
        default = { };
        example = literalExpression ''
          {
            Streaming = {
              current_scene = "Main";
              current_program_scene = "Main";
              scene_order = [ { name = "Main"; } ];
              sources = [ ];
            };
          }
        '';
        description = ''
          Scene collection JSON written to
          {file}`$XDG_CONFIG_HOME/obs-studio/basic/scenes/<name>.json`.
        '';
      };

      extraConfigFiles = mkOption {
        type = types.attrsOf fileType;
        default = { };
        description = ''
          Additional writable files installed relative to
          {file}`$XDG_CONFIG_HOME/obs-studio/plugin_config`.
        '';
      };
    };
  };

  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion = lib.all (
          profile: lib.all (file: file.source != null) (lib.attrValues profile.extraFiles)
        ) (lib.attrValues cfg.profiles);
        message = "programs.obs-studio.profiles.*.extraFiles entries must set source or text.";
      }
      {
        assertion = lib.all (file: file.source != null) (lib.attrValues cfg.extraConfigFiles);
        message = "programs.obs-studio.extraConfigFiles entries must set source or text.";
      }
      {
        assertion = lib.all safePathComponent (lib.attrNames cfg.profiles);
        message = "programs.obs-studio.profiles attribute names must be safe relative path components.";
      }
      {
        assertion = lib.all safePathComponent (lib.attrNames cfg.sceneCollections);
        message = "programs.obs-studio.sceneCollections attribute names must be safe relative path components.";
      }
      {
        assertion = lib.all safeRelativePath (lib.attrNames cfg.extraConfigFiles);
        message = "programs.obs-studio.extraConfigFiles attribute names must be safe relative paths.";
      }
      {
        assertion = lib.all (profile: lib.all safeRelativePath (lib.attrNames profile.extraFiles)) (
          lib.attrValues cfg.profiles
        );
        message = "programs.obs-studio.profiles.*.extraFiles attribute names must be safe relative paths.";
      }
      {
        assertion = lib.all (
          profile: listIntersection (lib.attrNames profile.extraFiles) (profileGeneratedPaths profile) == [ ]
        ) (lib.attrValues cfg.profiles);
        message = "programs.obs-studio.profiles.*.extraFiles must not override generated OBS profile files.";
      }
      {
        assertion = lib.all (
          name:
          !cfg.integrations.${name}.enable
          || builtins.hasAttr name pluginPackages
          || cfg.integrations.${name}.package != null
        ) (lib.attrNames cfg.integrations);
        message = "programs.obs-studio.integrations.*.enable requires a matching derivation in pkgs.obs-studio-plugins or an explicit package override.";
      }
      {
        assertion = lib.all (
          integration: lib.all (file: file.source != null) (lib.attrValues integration.extraConfigFiles)
        ) (lib.attrValues cfg.integrations);
        message = "programs.obs-studio.integrations.*.extraConfigFiles entries must set source or text.";
      }
      {
        assertion = lib.all safePathComponent (lib.attrNames cfg.integrations);
        message = "programs.obs-studio.integrations attribute names must be safe relative path components.";
      }
      {
        assertion = lib.all (
          integration: lib.all safeRelativePath (lib.attrNames integration.extraConfigFiles)
        ) (lib.attrValues cfg.integrations);
        message = "programs.obs-studio.integrations.*.extraConfigFiles attribute names must be safe relative paths.";
      }
      {
        assertion =
          listIntersection (lib.attrNames cfg.extraConfigFiles) (lib.attrNames integrationConfigPaths) == [ ];
        message = "programs.obs-studio.extraConfigFiles must not override generated integration config files.";
      }
    ];

    home.packages = [ cfg.finalPackage ];
    programs.obs-studio.finalPackage = pkgs.wrapOBS.override { obs-studio = cfg.package; } {
      plugins = lib.unique (cfg.plugins ++ enabledIntegrationPackages);
    };

    home.activation.obsStudioConfig = lib.hm.dag.entryAfter [ "linkGeneration" ] ''
      ${prepareRemovedFiles}
      ${removeStaleGeneratedFiles}
      ${installGeneratedFiles}
      ${installGeneratedManifest}
    '';
  };
}
