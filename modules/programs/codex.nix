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
  ];

  options.programs.codex = {
    enable = lib.mkEnableOption "Lightweight coding agent that runs in your terminal";

    package = lib.mkPackageOption pkgs "codex" { nullable = true; };

    enableMcpIntegration = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = ''
        Whether to integrate the MCP server config from
        {option}`programs.mcp.servers` into
        {option}`programs.codex.settings.mcp_servers`.

        Note: Settings defined in {option}`programs.mcp.servers` are merged
        with {option}`programs.codex.settings.mcp_servers`, with settings-based
        values taking precedence.
      '';
    };

    settings = lib.mkOption {
      # NOTE: `yaml` type supports null, using `nullOr` for backwards compatibility period
      type = lib.types.nullOr tomlFormat.type;
      description = ''
        Configuration written to {file}`CODEX_HOME/config.toml` (0.2.0+)
        or {file}`~/.codex/config.yaml` (<0.2.0). Per default {env}`CODEX_HOME`
        defaults to ~/.codex.
        See <https://developers.openai.com/codex/config-reference> for supported values.
      '';
      default = { };
      defaultText = lib.literalExpression "{ }";
      example = lib.literalExpression ''
        {
          model = "gemma3:latest";
          model_provider = "ollama";
          model_providers = {
            ollama = {
              name = "Ollama";
              base_url = "http://localhost:11434/v1";
              env_key = "OLLAMA_API_KEY";
            };
          };
          mcp_servers = {
            context7 = {
              command = "npx";
              args = [
                "-y"
                "@upstash/context7-mcp"
              ];
            };
          };
        }
      '';
    };

    profiles = lib.mkOption {
      type = lib.types.attrsOf tomlFormat.type;
      default = { };
      description = ''
        Named Codex configuration profiles written to
        {file}`CODEX_HOME/<name>.config.toml`.

        These profiles are selected with {command}`codex --profile <name>`.
        Codex 0.134.0 and later no longer reads profile settings from
        {option}`programs.codex.settings.profiles`, and the top-level
        {option}`programs.codex.settings.profile` selector is no longer
        supported.
      '';
      example = lib.literalExpression ''
        {
          deep-review = {
            model = "gpt-5.5";
            model_reasoning_effort = "xhigh";
            approval_policy = "on-request";
            sandbox_mode = "workspace-write";
          };
        }
      '';
    };

    context = lib.mkOption {
      type = lib.types.either lib.types.lines lib.types.path;
      description = ''
        Global context for Codex.

        The value is either:
        - Inline content as a string
        - A path to a file containing the content

        The configured content is written to
        {file}`CODEX_HOME/AGENTS.md`.
      '';
      default = "";
      example = lib.literalExpression ''
        '''
          - Always respond with emojis
          - Only use git commands when explicitly requested
        '''
      '';
    };

    contextOverride = lib.mkOption {
      type = lib.types.nullOr (lib.types.either lib.types.lines lib.types.path);
      description = ''
        Global override context for Codex.

        This has the same value format as {option}`programs.codex.context`,
        but writes {file}`CODEX_HOME/AGENTS.override.md`.

        Codex prefers {file}`AGENTS.override.md` over
        {file}`AGENTS.md` in the same directory.
      '';
      default = null;
      example = lib.literalExpression ''
        '''
          - Temporarily ignore default global guidance
          - Prefer brief answers while debugging
        '''
      '';
    };

    plugins = lib.mkOption {
      type = with lib.types; listOf (either package path);
      default = [ ];
      description = ''
        List of plugins to use when running Codex.
        Each entry is either:
        - A path to the plugin directory
        - The plugin package, whether a nix package or the output of a fetcher
        Plugins are installed into Codex's plugin cache and enabled through
        {file}`CODEX_HOME/config.toml`.

        Warning: If using a derivation as the source for a plugin, make sure that
        the derivation name matches the name of the plugin in the manifest file.
      '';
      example = lib.literalExpression ''
        [
          ./my-local-plugin
          (fetchFromGitHub {
            owner = "some-github-org";
            repo = "codex-plugin";
            rev = "779a68ebc2a75e4a184d2c87e5a43a758e6458a1";
            sha256 = "228fdd7e5908ea1d2f65218ecd9c71e1eefa0834d200d55fbb8bf8b5563acec0";
          })
        ]
      '';
    };

    marketplaces = lib.mkOption {
      type = with lib.types; attrsOf (either package path);
      default = { };
      description = ''
        Custom marketplaces for Codex plugins.
        The attribute name becomes the marketplace name, and the value is either:
        - A path to the marketplace directory
        - The marketplace package, whether a nix package or the output of a fetcher

        Marketplaces are configured through {file}`CODEX_HOME/config.toml`.
      '';
      example = lib.literalExpression ''
        {
          local-marketplace = ./my-local-marketplace;
          gh-marketplace = fetchFromGitHub {
            owner = "some-github-org";
            repo = "codex-marketplace";
            rev = "8a873a220b8427b25b03ce1a821593a24e098c34";
            sha256 = "5c2dce95122b5bb73fa547edabbb6c3061c2d193d11e51faecd4d22659e67279";
          };
        }
      '';
    };

    skills = lib.mkOption {
      type = lib.types.either (lib.types.attrsOf (lib.types.either lib.types.lines lib.types.path)) lib.types.path;
      default = { };
      description = ''
        Custom skills for Codex.

        This option can be either:
        - An attribute set defining skills
        - A path to a directory containing skill folders

        If an attribute set is used, the attribute name becomes the
        skill directory name, and the value is either:
        - Inline content as a string (creates a generated skill directory at {file}`<skills-dir>/<name>/`)
        - A path to a file (creates a generated skill directory at {file}`<skills-dir>/<name>/`)
        - A path to a directory (symlinks {file}`<skills-dir>/<name>/` to that directory)

        If a path is used, it is expected to contain one folder per
        skill name, each containing a {file}`SKILL.md`. Each top-level
        skill entry is symlinked into {file}`<skills-dir>/`, leaving
        {file}`<skills-dir>/` itself as a normal directory so unmanaged
        skills can coexist.

        Home Manager manages skills under {file}`CODEX_HOME/skills`
        (typically {file}`~/.codex/skills`, or
        {file}`~/.config/codex/skills` when
        {option}`home.preferXdgDirectories` is enabled).
      '';
      example = lib.literalExpression ''
        {
          pdf-processing = '''
            ---
            name: pdf-processing
            description: Extract text and tables from PDF files, fill forms, merge documents. Use when working with PDF files or when the user mentions PDFs, forms, or document extraction.
            ---

            # PDF Processing

            ## Quick start

            Use pdfplumber to extract text from PDFs:

            ```python
            import pdfplumber

            with pdfplumber.open("document.pdf") as pdf:
                text = pdf.pages[0].extract_text()
            ```
          ''';
          data-analysis = ./skills/data-analysis;
        }
      '';
    };

    rules = lib.mkOption {
      type = lib.types.attrsOf (lib.types.either lib.types.lines lib.types.path);
      default = { };
      description = ''
        Codex rules files to manage under {file}`CODEX_HOME/rules/`.

        The attribute name becomes the filename, with a {file}`.rules`
        extension added automatically. The value is either:
        - Inline content as a string
        - A path to an existing rules file

        This is useful for declaratively managing persistent
        `prefix_rule()` definitions, including the default
        {file}`default.rules` allow-list Codex writes when you accept
        recurring approvals interactively.
      '';
      example = lib.literalExpression ''
        {
          default = "prefix_rule(pattern = [\"nix\", \"build\"], decision = \"allow\")\n";
          github = ./codex/github.rules;
        }
      '';
    };
  };

  config =
    let
      useXdgDirectories = config.home.preferXdgDirectories && isTomlConfig;
      xdgConfigHome = lib.removePrefix config.home.homeDirectory config.xdg.configHome;
      configDir = if useXdgDirectories then "${xdgConfigHome}/codex" else ".codex";
      configFileName = if isTomlConfig then "config.toml" else "config.yaml";
      skillsDir = "${configDir}/skills";
      homeRelativeConfigDir = lib.removePrefix "/" configDir;
      pluginsMarketplaceName = "home-manager";
      pluginsDir = "${configDir}/plugins";
      pluginsCacheDir = "${pluginsDir}/cache";
      homeRelativePluginsCacheDir = "${homeRelativeConfigDir}/plugins/cache";
      rawSettings = if cfg.settings == null then { } else cfg.settings;

      # TODO: Remove this workaround once Codex supports symlinked SKILL.md
      # files again. Upstream only supports symlinking the containing skill
      # directory today: https://github.com/openai/codex/issues/10470
      mkSkillDir =
        content:
        pkgs.writeTextDir "SKILL.md" (
          if lib.hm.strings.isPathLike content then builtins.readFile content else content
        );
      skillSources =
        if builtins.isAttrs cfg.skills then
          cfg.skills
        else if lib.hm.strings.isPathLike cfg.skills && lib.pathIsDirectory cfg.skills then
          lib.mapAttrs (name: _type: cfg.skills + "/${name}") (builtins.readDir cfg.skills)
        else
          { };
      mkSkillEntry =
        name: content:
        if lib.hm.strings.isPathLike content && lib.pathIsDirectory content then
          lib.nameValuePair "${skillsDir}/${name}" {
            source = content;
          }
        else
          lib.nameValuePair "${skillsDir}/${name}" {
            source = mkSkillDir content;
          };
      mkRuleEntry =
        name: content:
        lib.nameValuePair "${configDir}/rules/${name}.rules" (
          if lib.hm.strings.isPathLike content then { source = content; } else { text = content; }
        );
      mkTextOrPathEntry =
        path: content:
        if lib.isPath content then
          lib.nameValuePair path { source = content; }
        else
          lib.nameValuePair path (lib.mkIf (content != "") { text = content; });
      mkPluginName =
        plugin:
        let
          manifestPath = plugin + "/.codex-plugin/plugin.json";
          manifestName =
            if !lib.isDerivation plugin && builtins.pathExists manifestPath then
              (builtins.fromJSON (builtins.readFile manifestPath)).name
            else
              null;
          fallbackName =
            if lib.isDerivation plugin then
              plugin.pname or (lib.getName plugin)
            else
              baseNameOf (toString plugin);
        in
        builtins.unsafeDiscardStringContext (if manifestName != null then manifestName else fallbackName);
      mkPluginVersion =
        plugin:
        let
          manifestPath = plugin + "/.codex-plugin/plugin.json";
          manifestVersion =
            if !lib.isDerivation plugin && builtins.pathExists manifestPath then
              (builtins.fromJSON (builtins.readFile manifestPath)).version or null
            else
              null;
          fallbackVersion = plugin.version or "0.0.0";
        in
        builtins.unsafeDiscardStringContext (
          if manifestVersion != null then manifestVersion else fallbackVersion
        );
      mkPluginCachePath =
        plugin:
        "${pluginsCacheDir}/${pluginsMarketplaceName}/${mkPluginName plugin}/${mkPluginVersion plugin}";
      mkPluginFileEntry =
        plugin:
        lib.nameValuePair (mkPluginCachePath plugin) {
          source = plugin;
          force = true;
        };
      mkPluginConfigEntry =
        plugin:
        lib.nameValuePair "${mkPluginName plugin}@${pluginsMarketplaceName}" {
          enabled = true;
        };
      mkMarketplaceConfigEntry = _name: content: {
        source_type = "local";
        source = "${content}";
      };
      mkPersonalMarketplacePluginEntry = plugin: {
        name = mkPluginName plugin;
        source = {
          source = "local";
          path = "./${homeRelativePluginsCacheDir}/${pluginsMarketplaceName}/${mkPluginName plugin}/${mkPluginVersion plugin}";
        };
        policy = {
          installation = "AVAILABLE";
          authentication = "ON_INSTALL";
        };
        category = "Productivity";
      };
      mkProfileEntry =
        name: settings:
        lib.nameValuePair "${configDir}/${name}.config.toml" {
          source = tomlFormat.generate "codex-${name}-config" settings;
        };

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
                path = "$HOME/${mkPluginCachePath plugin}";
              in
              ''
                if [ -d "${path}" ] && [ ! -L "${path}" ]; then
                  rm -rf "${path}"
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
          "${configDir}/AGENTS.md" =
            if lib.isPath cfg.context then
              { source = cfg.context; }
            else
              lib.mkIf (cfg.context != "") {
                text = cfg.context;
              };
        }
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
