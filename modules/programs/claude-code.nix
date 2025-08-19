{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.programs.claude-code;
  jsonFormat = pkgs.formats.json { };
in
{
  meta.maintainers = [ lib.maintainers.khaneliman ];

  options.programs.claude-code = {
    enable = lib.mkEnableOption "Claude Code, Anthropic's official CLI";

    package = lib.mkPackageOption pkgs "claude-code" { nullable = true; };

    finalPackage = lib.mkOption {
      type = lib.types.package;
      readOnly = true;
      internal = true;
      description = "Resulting customized claude-code package.";
    };

    settings = lib.mkOption {
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

    agents = lib.mkOption {
      type = lib.types.attrsOf lib.types.lines;
      default = { };
      description = ''
        Custom agents for Claude Code.
        The attribute name becomes the agent filename, and the value is the file content with frontmatter.
        Agents are stored in .claude/agents/ directory.
      '';
      example = {
        code-reviewer = ''
          ---
          name: code-reviewer
          description: Specialized code review agent
          tools: Read, Edit, Grep
          ---

          You are a senior software engineer specializing in code reviews.
          Focus on code quality, security, and maintainability.
        '';
        documentation = ''
          ---
          name: documentation
          description: Documentation writing assistant
          model: claude-3-5-sonnet-20241022
          tools: Read, Write, Edit
          ---

          You are a technical writer who creates clear, comprehensive documentation.
          Focus on user-friendly explanations and examples.
        '';
      };
    };

    commands = lib.mkOption {
      type = lib.types.attrsOf lib.types.lines;
      default = { };
      description = ''
        Custom commands for Claude Code.
        The attribute name becomes the command filename, and the value is the file content.
        Commands are stored in .claude/commands/ directory.
      '';
      example = {
        changelog = ''
          ---
          allowed-tools: Bash(git log:*), Bash(git diff:*)
          argument-hint: [version] [change-type] [message]
          description: Update CHANGELOG.md with new entry
          ---
          Parse the version, change type, and message from the input
          and update the CHANGELOG.md file accordingly.
        '';
        fix-issue = ''
          ---
          allowed-tools: Bash(git status:*), Read
          argument-hint: [issue-number]
          description: Fix GitHub issue following coding standards
          ---
          Fix issue #$ARGUMENTS following our coding standards and best practices.
        '';
        commit = ''
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
        '';
      };
    };

    mcpServers = lib.mkOption {
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

  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion = cfg.mcpServers == { } || cfg.package != null;
        message = "`programs.claude-code.package` cannot be null when `mcpServers` is configured";
      }
    ];

    programs.claude-code.finalPackage =
      let
        makeWrapperArgs = lib.flatten (
          lib.filter (x: x != [ ]) [
            (lib.optional (cfg.mcpServers != { }) [
              "--add-flags"
              "--mcp-config ${jsonFormat.generate "claude-code-mcp-config.json" { inherit (cfg) mcpServers; }}"
            ])
          ]
        );

        hasWrapperArgs = makeWrapperArgs != [ ];
      in
      if hasWrapperArgs then
        pkgs.symlinkJoin {
          name = "claude-code";
          paths = [ cfg.package ];
          nativeBuildInputs = [ pkgs.makeWrapper ];
          postBuild = ''
            wrapProgram $out/bin/claude ${lib.escapeShellArgs makeWrapperArgs}
          '';
          inherit (cfg.package) meta;
        }
      else
        cfg.package;

    home = {
      packages = lib.mkIf (cfg.package != null) [ cfg.finalPackage ];

      file = {
        ".claude/settings.json" = lib.mkIf (cfg.settings != { }) {
          source = jsonFormat.generate "claude-code-settings.json" (
            cfg.settings
            // {
              "$schema" = "https://json.schemastore.org/claude-code-settings.json";
            }
          );
        };
      }
      // lib.mapAttrs' (
        name: content:
        lib.nameValuePair ".claude/agents/${name}.md" {
          text = content;
        }
      ) cfg.agents
      // lib.mapAttrs' (
        name: content:
        lib.nameValuePair ".claude/commands/${name}.md" {
          text = content;
        }
      ) cfg.commands;
    };
  };
}
