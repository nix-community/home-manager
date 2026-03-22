{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.programs.cursor-agent;
  jsonFormat = pkgs.formats.json { };
  transformedMcpServers = lib.optionalAttrs (cfg.enableMcpIntegration && config.programs.mcp.enable) (
    lib.mapAttrs (
      name: server:
      (removeAttrs server [ "disabled" ])
      // (lib.optionalAttrs (server ? url) { type = "http"; })
      // (lib.optionalAttrs (server ? command) { type = "stdio"; })
      // {
        enabled = !(server.disabled or false);
      }
    ) config.programs.mcp.servers
  );

  mergedMcpServers = transformedMcpServers // cfg.mcpServers;
in
{
  options.programs.cursor-agent = {
    enable = lib.mkEnableOption "Cursor Agent, Cursor's agentic coding CLI";

    package = lib.mkPackageOption pkgs "cursor-cli" { nullable = true; };

    enableMcpIntegration = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = ''
        Whether to integrate the MCP servers config from
        {option}`programs.mcp.servers` into
        the Cursor Agent MCP configuration.

        Note: Settings defined in {option}`programs.mcp.servers` are merged
        with {option}`programs.cursor-agent.mcpServers`, with Cursor Agent servers
        taking precedence.
      '';
    };

    settings = lib.mkOption {
      inherit (jsonFormat) type;
      default = { };
      example = {
        editor.vimMode = false;
        permissions = {
          allow = [
            "Shell(git diff:*)"
            "Shell(git log:*)"
          ];
          deny = [
            "Shell(rm:*)"
            "Read(.env*)"
          ];
        };
        network.useHttp1ForAgent = false;
        attribution = {
          attributeCommitsToAgent = false;
          attributePRsToAgent = false;
        };
      };
      description = ''
        JSON configuration for Cursor Agent CLI.

        The `version` field is always set to `1` and does not need to be specified.

        See <https://cursor.com/docs/cli/reference/configuration> for available options.
      '';
    };

    mcpServers = lib.mkOption {
      type = lib.types.attrsOf jsonFormat.type;
      default = { };
      description = "MCP (Model Context Protocol) servers configuration";
      example = {
        context7 = {
          type = "http";
          url = "https://mcp.context7.com/mcp";
        };
        playwright = {
          type = "stdio";
          command = "npx";
          args = [
            "-y"
            "@playwright/mcp@latest"
          ];
        };
      };
    };

    rules = lib.mkOption {
      type = lib.types.attrsOf (lib.types.either lib.types.lines lib.types.path);
      default = { };
      description = ''
        Rule files for Cursor Agent.
        The attribute name becomes the rule filename, and the value is either:
        - Inline content as a string (with optional MDC frontmatter)
        - A path to a file containing the rule content
        Rules are stored in {file}`~/.cursor/rules/` directory.
      '';
      example = lib.literalExpression ''
        {
          code-style = '''
            ---
            description: "Code style guidelines"
            alwaysApply: true
            ---
            - Use consistent formatting
            - Follow language conventions
          ''';
          security = ./rules/security.mdc;
        }
      '';
    };

    rulesDir = lib.mkOption {
      type = lib.types.nullOr lib.types.path;
      default = null;
      description = ''
        Path to a directory containing rule files for Cursor Agent.
        Rule files from this directory will be symlinked to {file}`~/.cursor/rules/`.
      '';
      example = lib.literalExpression "./rules";
    };

    agents = lib.mkOption {
      type = lib.types.attrsOf (lib.types.either lib.types.lines lib.types.path);
      default = { };
      description = ''
        Custom agents for Cursor Agent.
        The attribute name becomes the agent filename, and the value is either:
        - Inline content as a string with frontmatter
        - A path to a file containing the agent content with frontmatter
        Agents are stored in {file}`~/.cursor/agents/` directory.
      '';
      example = lib.literalExpression ''
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

    agentsDir = lib.mkOption {
      type = lib.types.nullOr lib.types.path;
      default = null;
      description = ''
        Path to a directory containing agent files for Cursor Agent.
        Agent files from this directory will be symlinked to {file}`~/.cursor/agents/`.
      '';
      example = lib.literalExpression "./agents";
    };

    commands = lib.mkOption {
      type = lib.types.attrsOf (lib.types.either lib.types.lines lib.types.path);
      default = { };
      description = ''
        Custom commands for Cursor Agent.
        The attribute name becomes the command filename, and the value is either:
        - Inline content as a string
        - A path to a file containing the command content
        Commands are stored in {file}`~/.cursor/commands/` directory.
      '';
      example = lib.literalExpression ''
        {
          commit = '''
            Based on the current changes, create a single atomic git commit
            with a descriptive message following conventional commits.
          ''';
          fix-issue = ./commands/fix-issue.md;
        }
      '';
    };

    commandsDir = lib.mkOption {
      type = lib.types.nullOr lib.types.path;
      default = null;
      description = ''
        Path to a directory containing command files for Cursor Agent.
        Command files from this directory will be symlinked to {file}`~/.cursor/commands/`.
      '';
      example = lib.literalExpression "./commands";
    };

    skills = lib.mkOption {
      type = lib.types.attrsOf (lib.types.either lib.types.lines lib.types.path);
      default = { };
      description = ''
        Custom skills for Cursor Agent.
        The attribute name becomes the skill directory name, and the value is either:
        - Inline content as a string with frontmatter (creates {file}`~/.cursor/skills/<name>/SKILL.md`)
        - A path to a file (creates {file}`~/.cursor/skills/<name>/SKILL.md`)
        - A path to a directory (creates {file}`~/.cursor/skills/<name>/` with all files including SKILL.md)
      '';
      example = lib.literalExpression ''
        {
          pdf-processing = '''
            ---
            name: pdf-processing
            description: Extract text and tables from PDF files
            ---

            # PDF Processing

            Use pdfplumber to extract text from PDFs.
          ''';
          xlsx = ./skills/xlsx.md;
          data-analysis = ./skills/data-analysis;
        }
      '';
    };

    skillsDir = lib.mkOption {
      type = lib.types.nullOr lib.types.path;
      default = null;
      description = ''
        Path to a directory containing skill files for Cursor Agent.
        Skill files from this directory will be symlinked to {file}`~/.cursor/skills/`.
      '';
      example = lib.literalExpression "./skills";
    };
  };

  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion = !(cfg.rules != { } && cfg.rulesDir != null);
        message = "Cannot specify both `programs.cursor-agent.rules` and `programs.cursor-agent.rulesDir`";
      }
      {
        assertion = !(cfg.agents != { } && cfg.agentsDir != null);
        message = "Cannot specify both `programs.cursor-agent.agents` and `programs.cursor-agent.agentsDir`";
      }
      {
        assertion = !(cfg.commands != { } && cfg.commandsDir != null);
        message = "Cannot specify both `programs.cursor-agent.commands` and `programs.cursor-agent.commandsDir`";
      }
      {
        assertion = !(cfg.skills != { } && cfg.skillsDir != null);
        message = "Cannot specify both `programs.cursor-agent.skills` and `programs.cursor-agent.skillsDir`";
      }
    ];

    home = {
      packages = lib.mkIf (cfg.package != null) [ cfg.package ];

      file = {
        ".cursor/rules" = lib.mkIf (cfg.rulesDir != null) {
          source = cfg.rulesDir;
          recursive = true;
        };

        ".cursor/agents" = lib.mkIf (cfg.agentsDir != null) {
          source = cfg.agentsDir;
          recursive = true;
        };

        ".cursor/commands" = lib.mkIf (cfg.commandsDir != null) {
          source = cfg.commandsDir;
          recursive = true;
        };

        ".cursor/skills" = lib.mkIf (cfg.skillsDir != null) {
          source = cfg.skillsDir;
          recursive = true;
        };

        ".cursor/mcp.json" = lib.mkIf (mergedMcpServers != { }) {
          source = jsonFormat.generate "cursor-mcp.json" {
            mcpServers = mergedMcpServers;
          };
        };

      }
      // lib.mapAttrs' (
        name: content:
        lib.nameValuePair ".cursor/rules/${name}.md" (
          if lib.isPath content then { source = content; } else { text = content; }
        )
      ) cfg.rules
      // lib.mapAttrs' (
        name: content:
        lib.nameValuePair ".cursor/agents/${name}.md" (
          if lib.isPath content then { source = content; } else { text = content; }
        )
      ) cfg.agents
      // lib.mapAttrs' (
        name: content:
        lib.nameValuePair ".cursor/commands/${name}.md" (
          if lib.isPath content then { source = content; } else { text = content; }
        )
      ) cfg.commands
      // lib.mapAttrs' (
        name: content:
        if lib.isPath content && lib.pathIsDirectory content then
          lib.nameValuePair ".cursor/skills/${name}" {
            source = content;
            recursive = true;
          }
        else
          lib.nameValuePair ".cursor/skills/${name}/SKILL.md" (
            if lib.isPath content then { source = content; } else { text = content; }
          )
      ) cfg.skills;

      activation = lib.mkIf (cfg.settings != { }) {
        cursorAgentCliConfig =
          let
            staticSettings = jsonFormat.generate "cursor-cli-config.json" (
              {
                version = 1;
              }
              // cfg.settings
            );
            jq = lib.getExe pkgs.jq;
          in
          lib.hm.dag.entryAfter [ "linkGeneration" ] ''
            config_path="${config.home.homeDirectory}/.cursor/cli-config.json"
            mkdir -p "$(dirname "$config_path")"
            if [ ! -e "$config_path" ]; then
              echo '{}' > "$config_path"
            fi
            if ! ${jq} -S '. * $static[0]' \
                --slurpfile static ${staticSettings} \
                "$config_path" > "$config_path.tmp" 2>/dev/null; then
              ${jq} -S '.' ${staticSettings} > "$config_path.tmp"
            fi
            mv "$config_path.tmp" "$config_path"
          '';
      };
    };

  };
}
