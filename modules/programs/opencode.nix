{
  lib,
  pkgs,
  config,
  ...
}:
let
  inherit (lib)
    literalExpression
    mkEnableOption
    mkIf
    mkOption
    mkPackageOption
    ;

  cfg = config.programs.opencode;

  jsonFormat = pkgs.formats.json { };
in
{
  meta.maintainers = with lib.maintainers; [ delafthi ];

  options.programs.opencode = {
    enable = mkEnableOption "opencode";

    package = mkPackageOption pkgs "opencode" { nullable = true; };

    settings = mkOption {
      inherit (jsonFormat) type;
      default = { };
      example = literalExpression ''
        {
          theme = "opencode";
          model = "anthropic/claude-sonnet-4-20250514";
          autoshare = false;
          autoupdate = true;
        }
      '';
      description = ''
        Configuration written to {file}`$XDG_CONFIG_HOME/opencode/config.json`.
        See <https://opencode.ai/docs/config/> for the documentation.

        Note, `"$schema": "https://opencode.ai/config.json"` is automatically added to the configuration.
      '';
    };

    rules = lib.mkOption {
      type = lib.types.lines;
      default = "";
      example = lib.literalExpression ''
        '''
          # TypeScript Project Rules

          ## External File Loading

          CRITICAL: When you encounter a file reference (e.g., @rules/general.md), use your Read tool to load it on a need-to-know basis. They're relevant to the SPECIFIC task at hand.

          Instructions:

          - Do NOT preemptively load all references - use lazy loading based on actual need
          - When loaded, treat content as mandatory instructions that override defaults
          - Follow references recursively when needed

          ## Development Guidelines

          For TypeScript code style and best practices: @docs/typescript-guidelines.md
          For React component architecture and hooks patterns: @docs/react-patterns.md
          For REST API design and error handling: @docs/api-standards.md
          For testing strategies and coverage requirements: @test/testing-guidelines.md

          ## General Guidelines

          Read the following file immediately as it's relevant to all workflows: @rules/general-guidelines.md.
        '''
      '';
      description = ''
        You can provide global custom instructions to opencode; this value is
        written to {file}`$XDG_CONFIG_HOME/opencode/AGENTS.md`.
      '';
    };

    commands = lib.mkOption {
      type = lib.types.attrsOf lib.types.lines;
      default = { };
      description = ''
        Custom commands for opencode.
        The attribute name becomes the command filename, and the value is the file content.
        Commands are stored in ~/.config/opencode/command/ directory.
      '';
      example = {
        changelog = ''
          # Update Changelog Command

          Update CHANGELOG.md with a new entry for the specified version.
          Usage: /changelog [version] [change-type] [message]
        '';
        fix-issue = ''
          # Fix Issue Command

          Fix a GitHub issue following coding standards.
          Usage: /fix-issue [issue-number]
        '';
        commit = ''
          # Commit Command

          Create a git commit with proper message formatting.
          Usage: /commit [message]
        '';
      };
    };

    agents = lib.mkOption {
      type = lib.types.attrsOf lib.types.lines;
      default = { };
      description = ''
        Custom agents for opencode.
        The attribute name becomes the agent filename, and the value is the file content.
        Agents are stored in ~/.config/opencode/agent/ directory.
      '';
      example = {
        code-reviewer = ''
          # Code Reviewer Agent

          You are a senior software engineer specializing in code reviews.
          Focus on code quality, security, and maintainability.

          ## Guidelines
          - Review for potential bugs and edge cases
          - Check for security vulnerabilities
          - Ensure code follows best practices
          - Suggest improvements for readability and performance
        '';
        documentation = ''
          # Documentation Agent

          You are a technical writer who creates clear, comprehensive documentation.
          Focus on user-friendly explanations and examples.

          ## Guidelines
          - Write clear, concise documentation
          - Include practical examples
          - Use proper formatting and structure
          - Consider the target audience
        '';
      };
    };

  };

  config = mkIf cfg.enable {
    home.packages = mkIf (cfg.package != null) [ cfg.package ];

    xdg.configFile = {
      "opencode/config.json" = mkIf (cfg.settings != { }) {
        source = jsonFormat.generate "config.json" (
          {
            "$schema" = "https://opencode.ai/config.json";
          }
          // cfg.settings
        );
      };

      "opencode/AGENTS.md" = mkIf (cfg.rules != "") {
        text = cfg.rules;
      };
    }
    // lib.mapAttrs' (
      name: content:
      lib.nameValuePair "opencode/command/${name}.md" {
        text = content;
      }
    ) cfg.commands
    // lib.mapAttrs' (
      name: content:
      lib.nameValuePair "opencode/agent/${name}.md" {
        text = content;
      }
    ) cfg.agents;
  };
}
