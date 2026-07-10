{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib) literalExpression mkOption;

  jsonFormat = pkgs.formats.json { };

  mkContentOption =
    { description, example }:
    mkOption {
      type = lib.types.attrsOf (lib.types.either lib.types.lines lib.types.path);
      default = { };
      inherit description example;
    };

  mkDirOption =
    { description, example }:
    mkOption {
      type = lib.types.nullOr lib.types.path;
      default = null;
      inherit description example;
    };
in
{
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
      default = "${config.home.homeDirectory}/.claude";
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
          fetchFromGitHub {
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
          gh-marketplace = fetchFromGitHub {
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
      type = with lib.types; either (attrsOf (either lines path)) path;
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
}
