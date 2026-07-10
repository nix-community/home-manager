{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib)
    literalExpression
    mkChangedOptionModule
    mkOption
    nameValuePair
    optionalAttrs
    ;

  cfg = config.programs.claude-code;

  jsonFormat = pkgs.formats.json { };

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

  mkContentOption =
    {
      description,
      example ? null,
    }:
    mkOption (
      {
        type = lib.types.attrsOf (lib.types.either lib.types.lines lib.types.path);
        default = { };
        inherit description;
      }
      // optionalAttrs (example != null) { inherit example; }
    );

  mkDirOption =
    { description, example }:
    mkOption {
      type = lib.types.nullOr lib.types.path;
      default = null;
      inherit description example;
    };

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
  ];

  options.programs.claude-code = {
    enable = lib.mkEnableOption "Claude Code, Anthropic's official CLI";

    package = lib.mkPackageOption pkgs "claude-code" { nullable = true; };

    finalPackage = mkOption {
      type = lib.types.package;
      readOnly = true;
      internal = true;
      description = "Resulting customized claude-code package.";
    };

    enableMcpIntegration = mkOption {
      type = lib.types.bool;
      default = false;
      description = ''
        Whether to integrate the MCP servers config from
        {option}`programs.mcp.servers` into
        {option}`programs.claude-code.mcpServers`.

        Note: Settings defined in {option}`programs.mcp.servers` are merged
        with {option}`programs.claude-code.mcpServers`, with Claude Code servers
        taking precedence.

        Servers marked disabled (via `enabled = false` or `disabled = true`)
        are still written to {file}`.mcp.json` but rejected through
        `disabledMcpjsonServers` in {file}`settings.json`, since Claude Code
        has no per-server `enabled` field. This keeps a disabled server
        present (and re-enableable) instead of dropping it.
      '';
    };

    configDir = mkOption {
      type = lib.types.str;
      default = upstreamConfigDir;
      defaultText = literalExpression ''"''${config.home.homeDirectory}/.claude"'';
      example = literalExpression ''"''${config.xdg.configHome}/claude"'';
      description = ''
        Directory holding Claude Code's configuration files.

        Defaults to {file}`~/.claude`, matching the upstream
        {command}`claude` CLI default. The {env}`CLAUDE_CONFIG_DIR`
        environment variable is exported automatically whenever the
        directory differs from this default so the CLI reads
        configuration from the same location.
      '';
    };

    settings = mkOption {
      inherit (jsonFormat) type;
      default = { };
      example = {
        theme = "dark";
        permissions = {
          allow = [
            "Bash(git diff:*)"
            "Edit"
          ];
          ask = [ "Bash(git push:*)" ];
          deny = [
            "WebFetch"
            "Bash(curl:*)"
            "Read(./.env)"
            "Read(./secrets/**)"
          ];
          additionalDirectories = [ "../docs/" ];
          defaultMode = "acceptEdits";
          disableBypassPermissionsMode = "disable";
        };
        model = "claude-3-5-sonnet-20241022";
        hooks = {
          PreToolUse = [
            {
              matcher = "Bash";
              hooks = [
                {
                  type = "command";
                  command = "echo 'Running command: $CLAUDE_TOOL_INPUT'";
                }
              ];
            }
          ];
          PostToolUse = [
            {
              matcher = "Edit|MultiEdit|Write";
              hooks = [
                {
                  type = "command";
                  command = "nix fmt $(jq -r '.tool_input.file_path' <<< '$CLAUDE_TOOL_INPUT')";
                }
              ];
            }
          ];
        };
        statusLine = {
          type = "command";
          command = "input=$(cat); echo \"[$(echo \"$input\" | jq -r '.model.display_name')] 📁 $(basename \"$(echo \"$input\" | jq -r '.workspace.current_dir')\")\"";
          padding = 0;
        };
        includeCoAuthoredBy = false;
      };
      description = "JSON configuration for Claude Code settings.json";
    };

    context = mkOption {
      type = lib.types.either lib.types.lines lib.types.path;
      default = "";
      description = ''
        Global context for Claude Code.

        The value is either:
        - Inline content as a string
        - A path to a file containing the content

        The configured content is written to
        {file}`CLAUDE.md` inside {option}`programs.claude-code.configDir`
        (default {file}`~/.claude/CLAUDE.md`).
      '';
      example = literalExpression "./claude-memory.md";
    };

    plugins = lib.mkOption {
      type = with lib.types; listOf (either package path);
      default = [ ];
      description = ''
        List of plugins to use when running Claude Code.
        Each entry is either:
        - A path to the plugin directory
        - The plugin package, whether a nix package or the output of a fetcher
        With Claude Code 2.1.157 or later, plugins are linked into
        {option}`programs.claude-code.configDir` and loaded as personal plugins.
        Versions 2.1.76 through 2.1.156 fall back to a legacy `--plugin-dir`
        wrapper, as do packages without detectable version metadata.
        Strict-parser subcommands such as {command}`claude rc` may reject
        arguments from that compatibility path.
      '';
      example = literalExpression ''
        [
          ./my-local-plugin
          fetchFromGithub {
            owner = "some-github-org";
            repo = "claude-plugin";
            rev = "779a68ebc2a75e4a184d2c87e5a43a758e6458a1";
            sha256 = "228fdd7e5908ea1d2f65218ecd9c71e1eefa0834d200d55fbb8bf8b5563acec0";
          }
        ]
      '';
    };

    marketplaces = lib.mkOption {
      type = with lib.types; attrsOf (either package path);
      default = { };
      description = ''
        Custom marketplaces for Claude Code plugins.
        The attribute name becomes the marketplace name, and the value is either:
        - A path to the marketplace directory
        - The marketplace package, whether a nix package or the output of a fetcher
      '';
      example = literalExpression ''
        {
          local-marketplace = ./my-local-marketplace;
          gh-marketplace = fetchFromGithub {
            owner = "some-github-org";
            repo = "claude-marketplace";
            rev = "8a873a220b8427b25b03ce1a821593a24e098c34";
            sha256 = "5c2dce95122b5bb73fa547edabbb6c3061c2d193d11e51faecd4d22659e67279";
          };
        }
      '';
    };

    agents = mkContentOption {
      description = ''
        Custom agents for Claude Code.
        The attribute name becomes the agent filename, and the value is either:
        - Inline content as a string with frontmatter
        - A path to a file containing the agent content with frontmatter
        Agents are stored in the {file}`agents/` subdirectory of
        {option}`programs.claude-code.configDir`.
      '';
      example = literalExpression ''
        {
          code-reviewer = '''
            ---
            name: code-reviewer
            description: Specialized code review agent
            tools: Read, Edit, Grep
            ---

            You are a senior software engineer specializing in code reviews.
            Focus on code quality, security, and maintainability.
          ''';
          documentation = ./agents/documentation.md;
        }
      '';
    };

    commands = mkContentOption {
      description = ''
        Custom commands for Claude Code.
        The attribute name becomes the command filename, and the value is either:
        - Inline content as a string
        - A path to a file containing the command content
        Commands are stored in the {file}`commands/` subdirectory of
        {option}`programs.claude-code.configDir`.
      '';
      example = literalExpression ''
        {
          changelog = '''
            ---
            allowed-tools: Bash(git log:*), Bash(git diff:*)
            argument-hint: [version] [change-type] [message]
            description: Update CHANGELOG.md with new entry
            ---
            Parse the version, change type, and message from the input
            and update the CHANGELOG.md file accordingly.
          ''';
          fix-issue = ./commands/fix-issue.md;
          commit = '''
            ---
            allowed-tools: Bash(git add:*), Bash(git status:*), Bash(git commit:*)
            description: Create a git commit with proper message
            ---
            ## Context

            - Current git status: !`git status`
            - Current git diff: !`git diff HEAD`
            - Recent commits: !`git log --oneline -5`

            ## Task

            Based on the changes above, create a single atomic git commit with a descriptive message.
          ''';
        }
      '';
    };

    hooks = mkOption {
      type = lib.types.attrsOf lib.types.lines;
      default = { };
      description = ''
        Custom hooks for Claude Code.
        The attribute name becomes the hook filename, and the value is the hook script content.
        Hooks are stored in the {file}`hooks/` subdirectory of
        {option}`programs.claude-code.configDir`.
      '';
      example = {
        pre-edit = ''
          #!/usr/bin/env bash
          echo "About to edit file: $1"
        '';
        post-commit = ''
          #!/usr/bin/env bash
          echo "Committed with message: $1"
        '';
      };
    };

    rules = mkContentOption {
      description = ''
        Modular rule files for Claude Code.
        The attribute name becomes the rule filename, and the value is either:
        - Inline content as a string
        - A path to a file containing the rule content
        Rules are stored in the {file}`rules/` subdirectory of
        {option}`programs.claude-code.configDir`. All markdown files in
        that directory are automatically loaded as project memory.
      '';
      example = literalExpression ''
        {
          code-style = '''
            # Code Style Guidelines

            - Use consistent formatting
            - Follow language conventions
          ''';
          testing = '''
            # Testing Conventions

            - Write tests for all new features
            - Maintain test coverage above 80%
          ''';
          security = ./rules/security.md;
        }
      '';
    };

    rulesDir = mkDirOption {
      description = ''
        Path to a directory containing rule files for Claude Code.
        Rule files from this directory will be symlinked into the
        {file}`rules/` subdirectory of
        {option}`programs.claude-code.configDir`. All markdown files in
        this directory are automatically loaded as project memory.
      '';
      example = literalExpression "./rules";
    };

    agentsDir = mkDirOption {
      description = ''
        Path to a directory containing agent files for Claude Code.
        Agent files from this directory will be symlinked into the
        {file}`agents/` subdirectory of
        {option}`programs.claude-code.configDir`.
      '';
      example = literalExpression "./agents";
    };

    commandsDir = mkDirOption {
      description = ''
        Path to a directory containing command files for Claude Code.
        Command files from this directory will be symlinked into the
        {file}`commands/` subdirectory of
        {option}`programs.claude-code.configDir`.
      '';
      example = literalExpression "./commands";
    };

    hooksDir = mkDirOption {
      description = ''
        Path to a directory containing hook files for Claude Code.
        Hook files from this directory will be symlinked into the
        {file}`hooks/` subdirectory of
        {option}`programs.claude-code.configDir`.
      '';
      example = literalExpression "./hooks";
    };

    outputStyles = mkContentOption {
      description = ''
        Custom output styles for Claude Code.
        The attribute name becomes the base of the output style filename.
        The value is either:
          - Inline content as a string
          - A path to a file
        In both cases, the contents will be written to
        {file}`output-styles/<name>.md` inside
        {option}`programs.claude-code.configDir`.
      '';
      example = literalExpression ''
        {
          concise = ./output-styles/concise.md;
          detailed = '''
            # Detailed Output Style

            Contents will be used verbatim for the detailed output format.
          ''';
        }
      '';
    };

    skills = mkOption {
      type = lib.types.either (lib.types.attrsOf (
        lib.types.oneOf [
          lib.types.lines
          lib.types.path
          lib.types.str
        ]
      )) lib.types.path;
      default = { };
      description = ''
        Custom skills for Claude Code.

        This option can be either:
        - An attribute set defining skills
        - A path to a directory containing skill folders

        If an attribute set is used, the attribute name becomes the
        skill directory name, and the value is either:
        - Inline content as a string (creates {file}`skills/<name>/SKILL.md`)
        - A path to a file (creates {file}`skills/<name>/SKILL.md`)
        - A path to a directory (creates {file}`skills/<name>/` with all files)

        This also accepts Nix store paths, for example a skill directory
        from a package.

        If a path is used, it is expected to contain one folder per
        skill name, each containing a {file}`SKILL.md`. The directory is
        symlinked into the {file}`skills/` subdirectory of
        {option}`programs.claude-code.configDir`.
      '';
      example = literalExpression ''
        {
          xlsx = ./skills/xlsx/SKILL.md;
          data-analysis = ./skills/data-analysis;
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

          # A skill can also be a subdirectory within a package source (store path)
          beads = "''${pkgs.beads.src}/claude-plugin/skills/beads";
        }
      '';
    };

    lspServers = mkOption {
      type = lib.types.attrsOf jsonFormat.type;
      default = { };
      description = ''
        LSP (Language Server Protocol) servers configuration.
      '';
      example = {
        go = {
          command = "gopls";
          args = [ "serve" ];
          extensionToLanguage = {
            ".go" = "go";
          };
        };
        typescript = {
          command = "typescript-language-server";
          args = [ "--stdio" ];
          extensionToLanguage = {
            ".ts" = "typescript";
            ".tsx" = "typescriptreact";
            ".js" = "javascript";
            ".jsx" = "javascriptreact";
          };
        };
      };
    };

    mcpServers = mkOption {
      type = lib.types.attrsOf jsonFormat.type;
      default = { };
      description = "MCP (Model Context Protocol) servers configuration";
      example = {
        github = {
          type = "http";
          url = "https://api.githubcopilot.com/mcp/";
        };
        filesystem = {
          type = "stdio";
          command = "npx";
          args = [
            "-y"
            "@modelcontextprotocol/server-filesystem"
            "/tmp"
          ];
        };
        database = {
          type = "stdio";
          command = "npx";
          args = [
            "-y"
            "@bytebase/dbhub"
            "--dsn"
            "postgresql://user:pass@localhost:5432/db"
          ];
          env = {
            DATABASE_URL = "postgresql://user:pass@localhost:5432/db";
          };
        };
        customTransport = {
          type = "websocket";
          url = "wss://example.com/mcp";
          customOption = "value";
          timeout = 5000;
        };
      };
    };
  };

  config =
    let
      mkSourceEntry = content: if lib.isPath content then { source = content; } else { text = content; };

      mkMarkdownEntries =
        subdir: attrs:
        lib.mapAttrs' (
          name: content: nameValuePair "${cfg.configDir}/${subdir}/${name}.md" (mkSourceEntry content)
        ) attrs;

      mkHookEntries =
        attrs:
        lib.mapAttrs' (
          name: content:
          nameValuePair "${cfg.configDir}/hooks/${name}" {
            text = content;
            executable = true;
          }
        ) attrs;

      mkRecursiveDirAttrs =
        subdir: dir:
        optionalAttrs (dir != null) {
          "${cfg.configDir}/${subdir}" = {
            source = dir;
            recursive = true;
          };
        };

      mkSkillEntry =
        name: content:
        if lib.hm.strings.isPathLike content && lib.pathIsDirectory content then
          nameValuePair "${cfg.configDir}/skills/${name}" {
            source = content;
            recursive = true;
          }
        else
          nameValuePair "${cfg.configDir}/skills/${name}/SKILL.md" (
            if lib.hm.strings.isPathLike content then { source = content; } else { text = content; }
          );

      mkMarketplaceEntry = _name: content: {
        source = {
          source = "directory";
          path = content;
        };
      };

      mkInstalledMarketplaceEntry =
        name: content:
        (mkMarketplaceEntry name content)
        // {
          installLocation = content;
          lastUpdated = "1970-01-01T00:00:00Z";
        };

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

      mkPluginEntry =
        plugin:
        let
          name = builtins.unsafeDiscardStringContext (
            lib.strings.sanitizeDerivationName (baseNameOf (toString plugin))
          );
        in
        {
          inherit name;
          source = pkgs.symlinkJoin {
            name = "claude-code-${name}";
            paths = [ plugin ];
            postBuild = ''
              if [[ ! -e $out/.claude-plugin/plugin.json ]]; then
                install -Dm644 ${
                  jsonFormat.generate "claude-code-${name}.json" {
                    inherit name;
                  }
                } $out/.claude-plugin/plugin.json
              fi
            '';
          };
        };

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
