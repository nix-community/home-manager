{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib)
    mkChangedOptionModule
    nameValuePair
    optionalAttrs
    ;

  cfg = config.programs.claude-code;

  jsonFormat = pkgs.formats.json { };
  claudeCodeLib = import ./lib.nix { inherit lib pkgs; };

  packageVersion = if cfg.package == null then null else lib.getVersion cfg.package;
  hasPackageVersion = packageVersion != null && packageVersion != "";

  # A null package has no detectable version, so assume the latest Claude Code
  # and enable version-gated behavior by default. Preserve the legacy wrapper
  # for non-null packages without version metadata.
  atLeast =
    version: cfg.package == null || (hasPackageVersion && lib.versionAtLeast packageVersion version);
  supportsPluginDir = !hasPackageVersion || atLeast "2.1.76";
  supportsPersonalPlugins = atLeast "2.1.157";

  upstreamConfigDir = "${config.home.homeDirectory}/.claude";

  isMcpServerEnabled =
    server:
    let
      enabled = server.enabled or null;
      disabled = (server.disabled or false) == true;
    in
    enabled != false && !disabled;

  transformMcpServer =
    name: server:
    lib.hm.mcp.transformMcpServer {
      inherit server;
      exclude = [ "enabled" ];
      extraTransforms = [
        lib.hm.mcp.addType
        (lib.hm.mcp.wrapEnvFilesCommand { inherit pkgs name; }) # envFiles currently still need wrapping https://github.com/anthropics/claude-code/issues/28942
      ];
    };

  # Shared MCP servers participate only when both integrations are enabled.
  sharedMcpServers = lib.optionalAttrs (
    cfg.enableMcpIntegration && config.programs.mcp.enable
  ) config.programs.mcp.servers;

  transformedMcpServers = lib.mapAttrs transformMcpServer sharedMcpServers;

  disabledMcpServerNames = lib.attrNames (
    lib.filterAttrs (_: server: !(isMcpServerEnabled server)) (sharedMcpServers // cfg.mcpServers)
  );

in
{
  meta.maintainers = [ lib.maintainers.khaneliman ];

  imports = [
    (mkChangedOptionModule
      [ "programs" "claude-code" "memory" "text" ]
      [ "programs" "claude-code" "context" ]
      (config: lib.getAttrFromPath [ "programs" "claude-code" "memory" "text" ] config)
    )
    (mkChangedOptionModule
      [ "programs" "claude-code" "memory" "source" ]
      [ "programs" "claude-code" "context" ]
      (config: lib.getAttrFromPath [ "programs" "claude-code" "memory" "source" ] config)
    )
    (mkChangedOptionModule
      [ "programs" "claude-code" "skillsDir" ]
      [ "programs" "claude-code" "skills" ]
      (config: lib.getAttrFromPath [ "programs" "claude-code" "skillsDir" ] config)
    )
    ./options.nix
  ];

  config =
    let
      helpers = claudeCodeLib.mkHelpers { inherit (cfg) configDir; };
      inherit (helpers)
        mkHookEntries
        mkInstalledMarketplaceEntry
        mkMarkdownEntries
        mkMarketplaceEntry
        mkPluginEntry
        mkRecursiveDirAttrs
        mkSkillEntry
        ;

      mergedMcpServers =
        transformedMcpServers
        // lib.mapAttrs (_: server: removeAttrs (lib.hm.mcp.addType server) [ "enabled" ]) cfg.mcpServers;

      generatedPluginFiles =
        lib.optional (mergedMcpServers != { }) {
          name = ".mcp.json";
          path = jsonFormat.generate "claude-code-mcp.json" { mcpServers = mergedMcpServers; };
        }
        ++ lib.optional (cfg.lspServers != { }) {
          name = ".lsp.json";
          path = jsonFormat.generate "claude-code-lsp.json" cfg.lspServers;
        };

      generatedPlugin = pkgs.runCommand "claude-code-hm-plugin" { } (
        ''
          install -Dm644 ${
            jsonFormat.generate "claude-code-plugin.json" {
              name = "claude-code-home-manager";
            }
          } $out/.claude-plugin/plugin.json
        ''
        + lib.concatLines (
          map (pluginFile: "install -Dm644 ${pluginFile.path} $out/${pluginFile.name}") generatedPluginFiles
        )
      );

      pluginEntries =
        lib.optional (generatedPluginFiles != [ ]) {
          name = "claude-code-home-manager";
          source = generatedPlugin;
        }
        ++ map mkPluginEntry cfg.plugins;

      legacyPluginPaths = lib.optional (generatedPluginFiles != [ ]) generatedPlugin ++ cfg.plugins;

      hasManagedPlugins = legacyPluginPaths != [ ];
      useLegacyPluginWrapper = hasManagedPlugins && !supportsPersonalPlugins;

      legacyWrapperArgs = lib.flatten (
        map (plugin: [
          "--plugin-dir"
          "${plugin}"
        ]) legacyPluginPaths
      );

      legacyFinalPackage = pkgs.symlinkJoin {
        name = "claude-code";
        paths = [ cfg.package ];
        postBuild = ''
          mv $out/bin/claude $out/bin/.claude-wrapped
          cat > $out/bin/claude <<EOF
          #! ${pkgs.bash}/bin/bash -e
          exec -a "\$0" "$out/bin/.claude-wrapped" ${lib.escapeShellArgs legacyWrapperArgs} "\$@"
          EOF
          chmod +x $out/bin/claude
        '';
        inherit (cfg.package) meta;
      };

      pluginNames = map (plugin: plugin.name) pluginEntries;

      skillNames =
        if builtins.isAttrs cfg.skills then
          lib.attrNames cfg.skills
        else if lib.hm.strings.isPathLike cfg.skills && lib.pathIsDirectory cfg.skills then
          lib.attrNames (builtins.readDir cfg.skills)
        else
          [ ];

      pluginFileEntries = lib.optionalAttrs supportsPersonalPlugins (
        lib.listToAttrs (
          map (
            plugin:
            nameValuePair "${cfg.configDir}/skills/${plugin.name}" {
              inherit (plugin) source;
              recursive = true;
            }
          ) pluginEntries
        )
      );

    in
    lib.mkIf cfg.enable {
      warnings = lib.optional (useLegacyPluginWrapper && supportsPluginDir) ''
        `programs.claude-code.package` ${
          if hasPackageVersion then "version ${packageVersion}" else "has no detectable version and"
        }
        uses the legacy `--plugin-dir` wrapper. Strict-parser subcommands such
        as `claude rc` may reject managed MCP, LSP, or plugin arguments. Upgrade
        Claude Code to version 2.1.157 or later to use persistent personal
        plugins instead.
      '';

      assertions =
        let
          exclusiveInlineDirNames = [
            "rules"
            "agents"
            "commands"
            "hooks"
          ];

          mkExclusiveAssertion = inline: {
            assertion = !(cfg.${inline} != { } && cfg.${inline + "Dir"} != null);
            message = "Cannot specify both `programs.claude-code.${inline}` and `programs.claude-code.${inline}Dir`";
          };
        in
        [
          {
            assertion = !hasManagedPlugins || supportsPluginDir;
            message = "Managed Claude Code MCP, LSP, and plugins require `programs.claude-code.package` version 2.1.76 or later";
          }
          {
            assertion = !lib.hm.strings.isPathLike cfg.skills || lib.pathIsDirectory cfg.skills;
            message = "`programs.claude-code.skills` must be a directory when set to a path";
          }
          {
            assertion =
              !supportsPersonalPlugins || lib.length pluginNames == lib.length (lib.unique pluginNames);
            message = "`programs.claude-code.plugins` entries must resolve to unique personal-plugin directory names";
          }
          {
            assertion = !supportsPersonalPlugins || lib.intersectLists skillNames pluginNames == [ ];
            message = "`programs.claude-code.skills` and managed plugins must have unique directory names";
          }
        ]
        ++ map mkExclusiveAssertion exclusiveInlineDirNames;

      programs.claude-code.finalPackage = lib.mkIf (cfg.package != null) (
        if useLegacyPluginWrapper then legacyFinalPackage else cfg.package
      );

      home = {
        packages = lib.mkIf (cfg.package != null) [ cfg.finalPackage ];

        sessionVariables = lib.mkIf (cfg.configDir != upstreamConfigDir) {
          CLAUDE_CONFIG_DIR = cfg.configDir;
        };

        file = lib.mkMerge [
          (lib.mkIf (cfg.settings != { } || cfg.marketplaces != { } || disabledMcpServerNames != [ ]) {
            "${cfg.configDir}/settings.json".source = jsonFormat.generate "claude-code-settings.json" (
              cfg.settings
              // {
                "$schema" = "https://json.schemastore.org/claude-code-settings.json";
              }
              // optionalAttrs (cfg.marketplaces != { }) {
                extraKnownMarketplaces = lib.mapAttrs mkMarketplaceEntry cfg.marketplaces;
              }
              // optionalAttrs (disabledMcpServerNames != [ ]) {
                disabledMcpjsonServers = lib.unique (
                  (cfg.settings.disabledMcpjsonServers or [ ]) ++ disabledMcpServerNames
                );
              }
            );
          })
          (
            if lib.isPath cfg.context then
              {
                "${cfg.configDir}/CLAUDE.md".source = cfg.context;
              }
            else
              (lib.mkIf (cfg.context != "") {
                "${cfg.configDir}/CLAUDE.md".text = cfg.context;
              })
          )
          (lib.mkIf (cfg.marketplaces != { }) {
            "${cfg.configDir}/plugins/known_marketplaces.json".source =
              jsonFormat.generate "claude-code-known-marketplaces.json" (
                lib.mapAttrs mkInstalledMarketplaceEntry cfg.marketplaces
              );
          })
          (mkMarkdownEntries "agents" cfg.agents)
          (mkMarkdownEntries "commands" cfg.commands)
          (mkMarkdownEntries "rules" cfg.rules)
          (mkRecursiveDirAttrs "agents" cfg.agentsDir)
          (mkRecursiveDirAttrs "commands" cfg.commandsDir)
          (mkRecursiveDirAttrs "hooks" cfg.hooksDir)
          (mkRecursiveDirAttrs "rules" cfg.rulesDir)
          (lib.mkIf (lib.hm.strings.isPathLike cfg.skills) {
            "${cfg.configDir}/skills" = {
              source = cfg.skills;
              recursive = true;
            };
          })
          pluginFileEntries
          (mkHookEntries cfg.hooks)
          (lib.optionalAttrs (builtins.isAttrs cfg.skills) (lib.mapAttrs' mkSkillEntry cfg.skills))
          (mkMarkdownEntries "output-styles" cfg.outputStyles)
        ];
      };
    };
}
