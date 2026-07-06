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
      hookScriptDirs = [ "${configDir}/hooks" ] ++ lib.optional useXdgDirectories ".codex/hooks";
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
          plugins = lib.listToAttrs (map mkPluginConfigEntry cfg.plugins);
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
      hooksArePath = lib.hm.strings.isPathLike cfg.hooks;
      hooksAreDir = hooksArePath && lib.pathIsDirectory cfg.hooks;
      hooksJsonSource = if hooksAreDir then cfg.hooks + "/hooks.json" else cfg.hooks;
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
          assertion = lib.all (
            plugin:
            !(lib.hm.strings.isPathLike plugin && !lib.isDerivation plugin) || lib.pathIsDirectory plugin
          ) cfg.plugins;
          message = "`programs.codex.plugins` entries must be directories";
        }
        {
          assertion = lib.all (
            marketplace:
            !(lib.hm.strings.isPathLike marketplace && !lib.isDerivation marketplace)
            || lib.pathIsDirectory marketplace
          ) (lib.attrValues cfg.marketplaces);
          message = "`programs.codex.marketplaces` entries must be directories";
        }
        {
          assertion = !lib.hm.strings.isPathLike cfg.skills || lib.pathIsDirectory cfg.skills;
          message = "`programs.codex.skills` must be a directory when set to a path";
        }
        {
          assertion = lib.all (content: !(lib.hm.strings.isPathLike content && lib.pathIsDirectory content)) (
            lib.attrValues cfg.rules
          );
          message = "`programs.codex.rules` attribute values must be files when set to paths";
        }
        {
          assertion = !(hooksAreDir && !builtins.pathExists hooksJsonSource);
          message = "`programs.codex.hooks` directory must contain a hooks.json file";
        }
      ];

      home = {
        packages = mkIf (cfg.package != null) [ cfg.package ];

        # This is needed because codex will convert the symlinked plugin directory into
        # an actual directory (which will not be overwritten by home-manager)
        activation.cleanCodexPluginCache = lib.mkIf (cfg.plugins != [ ]) (
          lib.hm.dag.entryBefore [ "linkGeneration" ] (
            lib.concatMapStringsSep "\n" (
              plugin:
              let
                cachePath = lib.escapeShellArg (mkPluginCachePath plugin);
              in
              ''
                path="$HOME"/${cachePath}
                if [ -d "$path" ] && [ ! -L "$path" ]; then
                  rm -rf "$path"
                fi
              ''
            ) cfg.plugins
          )
        );

        file = {
          "${configDir}/${configFileName}" = lib.mkIf (mergedSettings != { }) {
            source = settingsFormat.generate "codex-config" mergedSettings;
          };
          ".agents/plugins/marketplace.json" = lib.mkIf (cfg.plugins != [ ]) {
            source = jsonFormat.generate "codex-home-manager-marketplace" {
              name = pluginsMarketplaceName;
              interface.displayName = "Home Manager";
              plugins = map mkPersonalMarketplacePluginEntry cfg.plugins;
            };
          };
          "${configDir}/hooks.json" = lib.mkIf (cfg.hooks != { }) {
            source =
              if hooksArePath then
                hooksJsonSource
              else
                jsonFormat.generate "codex-hooks" { inherit (cfg) hooks; };
          };
        }
        // lib.optionalAttrs hooksAreDir (
          lib.genAttrs hookScriptDirs (_: {
            source = cfg.hooks;
            recursive = true;
          })
        )
        // lib.listToAttrs [ (mkTextOrPathEntry "${configDir}/AGENTS.md" cfg.context) ]
        // lib.optionalAttrs (cfg.contextOverride != null) (
          lib.listToAttrs [ (mkTextOrPathEntry "${configDir}/AGENTS.override.md" cfg.contextOverride) ]
        )
        // lib.mapAttrs' mkProfileEntry mergedProfiles
        // lib.mapAttrs' mkSkillEntry skillSources
        // lib.listToAttrs (map mkPluginFileEntry cfg.plugins)
        // lib.mapAttrs' mkRuleEntry cfg.rules;

        sessionVariables = mkIf useXdgDirectories {
          CODEX_HOME = "${config.xdg.configHome}/codex";
        };
      };
    };
}
