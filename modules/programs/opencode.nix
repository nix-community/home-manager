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
      type = lib.types.either lib.types.lines lib.types.path;
      default = "";
      description = ''
         You can provide global custom instructions to opencode.
         The value is either:
         - Inline content as a string
         - A path to a file containing the content
        This value is written to {file}`$XDG_CONFIG_HOME/opencode/AGENTS.md`.
      '';
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
    };

    commands = lib.mkOption {
      type = lib.types.attrsOf (lib.types.either lib.types.lines lib.types.path);
      default = { };
      description = ''
        Custom commands for opencode.
        The attribute name becomes the command filename, and the value is either:
        - Inline content as a string
        - A path to a file containing the command content
        Commands are stored in {file}`$XDG_CONFIG_HOME/.config/opencode/command/` directory.
      '';
      example = lib.literalExpression ''
        {
          changelog = '''
            # Update Changelog Command

            Update CHANGELOG.md with a new entry for the specified version.
            Usage: /changelog [version] [change-type] [message]
          ''';
          fix-issue = ./commands/fix-issue.md;
          commit = '''
            # Commit Command

            Create a git commit with proper message formatting.
            Usage: /commit [message]
          ''';
        }
      '';
    };

    agents = lib.mkOption {
      type = lib.types.attrsOf (lib.types.either lib.types.lines lib.types.path);
      default = { };
      description = ''
        Custom agents for opencode.
        The attribute name becomes the agent filename, and the value is either:
        - Inline content as a string
        - A path to a file containing the agent content
        Agents are stored in {file}`$XDG_CONFIG_HOME/.config/opencode/agent/` directory.
      '';
      example = lib.literalExpression ''
        {
          code-reviewer = '''
            # Code Reviewer Agent

            You are a senior software engineer specializing in code reviews.
            Focus on code quality, security, and maintainability.

            ## Guidelines
            - Review for potential bugs and edge cases
            - Check for security vulnerabilities
            - Ensure code follows best practices
            - Suggest improvements for readability and performance
          ''';
          documentation = ./agents/documentation.md;
        }
      '';
    };

    themes = mkOption {
      type = lib.types.attrsOf (lib.types.either jsonFormat.type lib.types.path);
      default = { };
      description = ''
        Custom themes for opencode. The attribute name becomes the theme
        filename, and the value is either:
        - An attribute set, that is converted to a json
        - A path to a file conaining the content
        Themes are stored in {file}`$XDG_CONFIG_HOME/opencode/themes/` directory.
        Set `programs.opencode.settings.theme` to enable the custom theme.
        See <https://opencode.ai/docs/themes/> for the documentation.
      '';
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

      "opencode/AGENTS.md" = (
        if lib.isPath cfg.rules then
          { source = cfg.rules; }
        else
          (mkIf (cfg.rules != "") {
            text = cfg.rules;
          })
      );
    }
    // lib.mapAttrs' (
      name: content:
      lib.nameValuePair "opencode/command/${name}.md" (
        if lib.isPath content then { source = content; } else { text = content; }
      )
    ) cfg.commands
    // lib.mapAttrs' (
      name: content:
      lib.nameValuePair "opencode/agent/${name}.md" (
        if lib.isPath content then { source = content; } else { text = content; }
      )
    ) cfg.agents
    // lib.mapAttrs' (
      name: content:
      lib.nameValuePair "opencode/themes/${name}.json" (
        if lib.isPath content then
          {
            source = content;
          }
        else
          {
            source = jsonFormat.generate "opencode-${name}.json" (
              {
                "$schema" = "https://opencode.ai/theme.json";
              }
              // content
            );
          }
      )
    ) cfg.themes;
  };
}
