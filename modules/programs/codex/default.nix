{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib) mkIf;

  cfg = config.programs.codex;

  tomlFormat = pkgs.formats.toml { };
  yamlFormat = pkgs.formats.yaml { };
  jsonFormat = pkgs.formats.json { };
  codexLib = import ./lib.nix { inherit lib pkgs; };

  # A null package has no detectable version, so assume the latest Codex and
  # enable version-gated behavior by default.
  atLeast = version: cfg.package == null || lib.versionAtLeast (lib.getVersion cfg.package) version;
  isTomlConfig = atLeast "0.2.0";
  migrateLegacyProfiles = atLeast "0.134.0";
  settingsFormat = if isTomlConfig then tomlFormat else yamlFormat;
in
{
  meta.maintainers = with lib.maintainers; [
    delafthi
    khaneliman
  ];

  imports = [
    (lib.mkRenamedOptionModule
      [ "programs" "codex" "custom-instructions" ]
      [ "programs" "codex" "context" ]
    )
    ./options.nix
  ];

  config =
    let
      useXdgDirectories = config.home.preferXdgDirectories && isTomlConfig;
      xdgConfigHome = lib.removePrefix config.home.homeDirectory config.xdg.configHome;
      configDir = if useXdgDirectories then "${xdgConfigHome}/codex" else ".codex";
      configFileName = if isTomlConfig then "config.toml" else "config.yaml";
      skillsDir = "${configDir}/skills";
      pluginsMarketplaceName = "home-manager";
      pluginsDir = "${configDir}/plugins";
      pluginsCacheDir = "${pluginsDir}/cache";
      homeRelativePluginsCacheDir = "${configDir}/plugins/cache";
      rawSettings = if cfg.settings == null then { } else cfg.settings;
      skillSources = codexLib.mkSkillSources cfg.skills;
      helpers = codexLib.mkHelpers {
        inherit
          configDir
          homeRelativePluginsCacheDir
          pluginsCacheDir
          pluginsMarketplaceName
          skillsDir
          tomlFormat
          ;
      };
      inherit (helpers)
        mkMarketplaceConfigEntry
        mkPersonalMarketplacePluginEntry
        mkPluginCachePath
        mkPluginConfigEntry
        mkPluginFileEntry
        mkProfileEntry
        mkRuleEntry
        mkSkillEntry
        mkTextOrPathEntry
        ;

      pluginEntries = lib.imap0 (
        index: plugin:
        let
          needsBuildTimeIdentity = codexLib.needsBuildTimePluginIdentity plugin;
        in
        {
          inherit needsBuildTimeIdentity plugin;
          placeholder = "__home_manager_derived_plugin_${toString index}__";
        }
      ) cfg.plugins;
      derivedPluginEntries = lib.filter (entry: entry.needsBuildTimeIdentity) pluginEntries;
      staticPluginEntries = lib.filter (entry: !entry.needsBuildTimeIdentity) pluginEntries;

      transformedMcpServers = lib.optionalAttrs (cfg.enableMcpIntegration && config.programs.mcp.enable) (
        lib.mapAttrs (
          name: server:
          # NOTE: Convert shared programs.mcp fields to Codex config keys:
          # - file-backed env entries are wrapped in a shell script that sets environment variables before exec
          # - "headers" is renamed to "http_headers"
          # See: https://developers.openai.com/codex/mcp#other-configuration-options
          lib.hm.mcp.transformMcpServer {
            inherit server;
            exclude = [
              "headers"
              "type"
            ];
            extraTransforms = [
              (s: s // lib.optionalAttrs (s.headers or { } != { }) { http_headers = s.headers; })
              lib.hm.mcp.addType
              (lib.hm.mcp.wrapEnvFilesCommand { inherit pkgs name; })
            ];
          }
        ) config.programs.mcp.servers
      );

      # TODO: remove this migration block in a future stateVersion once the
      # Codex 0.134 profile transition window has passed.
      hasLegacyProfileSettings =
        migrateLegacyProfiles && ((rawSettings ? profile) || (rawSettings ? profiles));
      legacyProfiles = lib.optionalAttrs (
        hasLegacyProfileSettings && builtins.isAttrs (rawSettings.profiles or null)
      ) rawSettings.profiles;
      mergedProfiles = legacyProfiles // cfg.profiles;
      baseSettings =
        if hasLegacyProfileSettings then
          lib.removeAttrs rawSettings [
            "profile"
            "profiles"
          ]
        else
          rawSettings;

      generatedPluginSettings =
        lib.optionalAttrs (cfg.plugins != [ ] || cfg.marketplaces != { }) {
          features.plugins = true;
        }
        // lib.optionalAttrs (cfg.plugins != [ ]) {
          plugins = lib.listToAttrs (
            map (
              entry:
              if entry.needsBuildTimeIdentity then
                lib.nameValuePair "${entry.placeholder}@${pluginsMarketplaceName}" { enabled = true; }
              else
                mkPluginConfigEntry entry.plugin
            ) pluginEntries
          );
        }
        // lib.optionalAttrs (cfg.marketplaces != { }) {
          marketplaces = lib.mapAttrs mkMarketplaceConfigEntry cfg.marketplaces;
        };
      mergedSettingsWithoutMcp = lib.recursiveUpdate baseSettings generatedPluginSettings;
      settingMcpServers = lib.attrByPath [ "mcp_servers" ] { } mergedSettingsWithoutMcp;
      mergedMcpServers = transformedMcpServers // settingMcpServers;

      mergedSettings =
        mergedSettingsWithoutMcp
        // lib.optionalAttrs (mergedMcpServers != { }) { mcp_servers = mergedMcpServers; };

      pluginMarketplace = {
        name = pluginsMarketplaceName;
        interface.displayName = "Home Manager";
        plugins = map (
          entry:
          if entry.needsBuildTimeIdentity then
            {
              name = entry.placeholder;
              source = {
                source = "local";
                path = entry.placeholder;
              };
              policy = {
                installation = "AVAILABLE";
                authentication = "ON_INSTALL";
              };
              category = "Productivity";
            }
          else
            mkPersonalMarketplacePluginEntry entry.plugin
        ) pluginEntries;
      };

      derivedPluginBundle =
        pkgs.runCommandLocal "codex-derived-plugins"
          {
            nativeBuildInputs = [
              pkgs.python3
              pkgs.remarshal
            ];
            passAsFile = [ "pluginSpecs" ];
            pluginSpecs = builtins.toJSON (
              map (entry: {
                inherit (entry) placeholder;
                source = toString entry.plugin;
                fallbackName = baseNameOf (toString entry.plugin);
              }) derivedPluginEntries
            );
          }
          ''
            mkdir -p "$out/cache"

            python3 ${./normalize-plugins.py} \
              "$pluginSpecsPath" \
              ${jsonFormat.generate "codex-config-with-derived-plugin-placeholders" mergedSettings} \
              ${jsonFormat.generate "codex-marketplace-with-derived-plugin-placeholders" pluginMarketplace} \
              "$out" \
              ${lib.escapeShellArg homeRelativePluginsCacheDir} \
              ${lib.escapeShellArg pluginsMarketplaceName}

            remarshal --if json --of toml "$out/config.json" "$out/config.toml"
          '';

      hooksArePath = lib.hm.strings.isPathLike cfg.hooks;
      hooksAreLiteralPath = lib.isPath cfg.hooks;
      hooksAreLiteralDirectory = hooksAreLiteralPath && lib.pathIsDirectory cfg.hooks;
      hooksNeedNormalization = hooksArePath && !hooksAreLiteralPath;
      hooksJsonSource = if hooksAreLiteralDirectory then cfg.hooks + "/hooks.json" else cfg.hooks;
      skillsArePath = lib.hm.strings.isPathLike cfg.skills;
      skillsNeedNormalization = skillsArePath && !lib.isPath cfg.skills;

      normalizedHooks = pkgs.runCommandLocal "codex-hooks" { } ''
        source=${lib.escapeShellArg "${cfg.hooks}"}
        mkdir -p "$out"
        if [[ -d "$source" ]]; then
          if [[ ! -f "$source/hooks.json" ]]; then
            echo "programs.codex.hooks directory must contain a hooks.json file" >&2
            exit 1
          fi
          ln -s "$source/hooks.json" "$out/hooks.json"
          ln -s "$source" "$out/hooks"
        elif [[ -f "$source" ]]; then
          ln -s "$source" "$out/hooks.json"
        else
          echo "programs.codex.hooks must be a file or directory when set to a path" >&2
          exit 1
        fi
      '';

      normalizedSkills = pkgs.runCommandLocal "codex-skills" { } ''
        source=${lib.escapeShellArg "${cfg.skills}"}
        if [[ ! -d "$source" ]]; then
          echo "programs.codex.skills must be a directory when set to a path" >&2
          exit 1
        fi

        mkdir -p "$out/stage" "$out/normalized"
        shopt -s dotglob nullglob
        for skill in "$source"/*; do
          name="''${skill##*/}"
          if [[ -d "$skill" ]]; then
            ln -s "$skill" "$out/stage/$name"
          elif [[ -f "$skill" ]]; then
            mkdir -p "$out/normalized/$name"
            cp "$skill" "$out/normalized/$name/SKILL.md"
            ln -s "$out/normalized/$name" "$out/stage/$name"
          else
            echo "Codex skill source '$skill' is neither a file nor a directory" >&2
            exit 1
          fi
        done
      '';
    in
    mkIf cfg.enable {
      warnings = lib.optional hasLegacyProfileSettings ''
        `programs.codex.settings.profile` and `programs.codex.settings.profiles`
        are no longer supported by Codex 0.134.0 and later. Home Manager
        now writes entries from `programs.codex.settings.profiles` to
        `CODEX_HOME/<name>.config.toml`. Move them to
        `programs.codex.profiles` and remove `programs.codex.settings.profile`.
      '';

      assertions = [
        {
          assertion = (cfg.plugins == [ ] && cfg.marketplaces == { }) || isTomlConfig;
          message = "`programs.codex.plugins` and `programs.codex.marketplaces` require Codex 0.2.0 or later";
        }
        {
          assertion = lib.all (plugin: !lib.isPath plugin || lib.pathIsDirectory plugin) cfg.plugins;
          message = "`programs.codex.plugins` entries must be directories";
        }
        {
          assertion = lib.all (marketplace: !lib.isPath marketplace || lib.pathIsDirectory marketplace) (
            lib.attrValues cfg.marketplaces
          );
          message = "`programs.codex.marketplaces` entries must be directories";
        }
        {
          assertion = !lib.isPath cfg.skills || lib.pathIsDirectory cfg.skills;
          message = "`programs.codex.skills` must be a directory when set to a path";
        }
        {
          assertion = lib.all (content: !(lib.isPath content && lib.pathIsDirectory content)) (
            lib.attrValues cfg.rules
          );
          message = "`programs.codex.rules` attribute values must be files when set to paths";
        }
        {
          assertion =
            !(
              lib.isPath cfg.hooks
              && lib.pathIsDirectory cfg.hooks
              && !builtins.pathExists (cfg.hooks + "/hooks.json")
            );
          message = "`programs.codex.hooks` directory must contain a hooks.json file";
        }
      ];

      home = {
        packages = mkIf (cfg.package != null) [ cfg.package ];

        # This is needed because codex will convert the symlinked plugin directory into
        # an actual directory (which will not be overwritten by home-manager)
        activation.cleanCodexPluginCache = lib.mkIf (cfg.plugins != [ ]) (
          lib.hm.dag.entryBefore [ "linkGeneration" ] (
            lib.concatStrings [
              (lib.concatMapStringsSep "\n" (
                entry:
                let
                  cachePath = lib.escapeShellArg (mkPluginCachePath entry.plugin);
                in
                ''
                  path="$HOME"/${cachePath}
                  if [ -d "$path" ] && [ ! -L "$path" ]; then
                    rm -rf "$path"
                  fi
                ''
              ) staticPluginEntries)
              (lib.optionalString (derivedPluginEntries != [ ]) ''
                for plugin in ${derivedPluginBundle}/cache/*/*; do
                  [ -L "$plugin" ] || continue
                  relativePath="''${plugin#${derivedPluginBundle}/cache/}"
                  path="$HOME"/${lib.escapeShellArg "${pluginsCacheDir}/${pluginsMarketplaceName}"}/"$relativePath"
                  if [ -d "$path" ] && [ ! -L "$path" ]; then
                    rm -rf "$path"
                  fi
                done
              '')
            ]
          )
        );

        file = {
          "${configDir}/${configFileName}" = lib.mkIf (mergedSettings != { }) {
            source =
              if derivedPluginEntries == [ ] then
                settingsFormat.generate "codex-config" mergedSettings
              else
                derivedPluginBundle + "/config.toml";
          };
          ".agents/plugins/marketplace.json" = lib.mkIf (cfg.plugins != [ ]) {
            source =
              if derivedPluginEntries == [ ] then
                jsonFormat.generate "codex-home-manager-marketplace" pluginMarketplace
              else
                derivedPluginBundle + "/marketplace.json";
          };
          "${configDir}/hooks.json" = lib.mkIf (!hooksNeedNormalization && cfg.hooks != { }) {
            source =
              if hooksArePath then
                hooksJsonSource
              else
                jsonFormat.generate "codex-hooks" { inherit (cfg) hooks; };
          };
        }
        // lib.optionalAttrs hooksAreLiteralDirectory {
          "${configDir}/hooks" = {
            source = cfg.hooks;
            recursive = true;
          };
        }
        // lib.optionalAttrs hooksNeedNormalization {
          "${configDir}" = {
            source = normalizedHooks;
            recursive = true;
          };
        }
        // lib.listToAttrs [ (mkTextOrPathEntry "${configDir}/AGENTS.md" cfg.context) ]
        // lib.optionalAttrs (cfg.contextOverride != null) (
          lib.listToAttrs [ (mkTextOrPathEntry "${configDir}/AGENTS.override.md" cfg.contextOverride) ]
        )
        // lib.mapAttrs' mkProfileEntry mergedProfiles
        // lib.mapAttrs' mkSkillEntry skillSources
        // lib.optionalAttrs skillsNeedNormalization {
          "${skillsDir}" = {
            source = normalizedSkills + "/stage";
            recursive = true;
            ignorelinks = true;
          };
        }
        // lib.listToAttrs (map (entry: mkPluginFileEntry entry.plugin) staticPluginEntries)
        // lib.optionalAttrs (derivedPluginEntries != [ ]) {
          "${pluginsCacheDir}/${pluginsMarketplaceName}" = {
            source = derivedPluginBundle + "/cache";
            recursive = true;
            ignorelinks = true;
          };
        }
        // lib.mapAttrs' mkRuleEntry cfg.rules;

        sessionVariables = mkIf useXdgDirectories {
          CODEX_HOME = "${config.xdg.configHome}/codex";
        };
      };
    };
}
