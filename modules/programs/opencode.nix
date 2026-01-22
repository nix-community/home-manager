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
  webCfg = cfg.web;

  jsonFormat = pkgs.formats.json { };

  transformMcpServer = name: server: {
    name = name;
    value = {
      enabled = !(server.disabled or false);
    }
    // (
      if server ? url then
        {
          type = "remote";
          url = server.url;
        }
        // (lib.optionalAttrs (server ? headers) { headers = server.headers; })
      else if server ? command then
        {
          type = "local";
          command = [ server.command ] ++ (server.args or [ ]);
        }
        // (lib.optionalAttrs (server ? env) { environment = server.env; })
      else
        { }
    );
  };

  transformedMcpServers =
    if cfg.enableMcpIntegration && config.programs.mcp.enable && config.programs.mcp.servers != { } then
      lib.listToAttrs (lib.mapAttrsToList transformMcpServer config.programs.mcp.servers)
    else
      { };
in
{
  meta.maintainers = with lib.maintainers; [ delafthi ];

  options.programs.opencode = {
    enable = mkEnableOption "opencode";

    package = mkPackageOption pkgs "opencode" { nullable = true; };

    enableMcpIntegration = mkOption {
      type = lib.types.bool;
      default = false;
      description = ''
        Whether to integrate the MCP servers config from
        {option}`programs.mcp.servers` into
        {option}`programs.opencode.settings.mcp`.

        Note: Settings defined in {option}`programs.mcp.servers` are merged
        with {option}`programs.opencode.settings.mcp`, with OpenCode settings
        taking precedence.
      '';
    };

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

    web = {
      enable = lib.mkEnableOption "opencode web service";

      extraArgs = mkOption {
        type = lib.types.listOf lib.types.str;
        default = [ ];
        example = [
          "--hostname"
          "0.0.0.0"
          "--port"
          "4096"
          "--mdns"
          "--cors"
          "https://example.com"
          "--cors"
          "http://localhost:3000"
          "--print-logs"
          "--log-level"
          "DEBUG"
        ];
        description = ''
          Extra arguments to pass to the opencode web command.

          These arguments override the "server" options defined in the configuration file.
          See <https://opencode.ai/docs/web/#config-file> for available options.
        '';
      };
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
      type = lib.types.either (lib.types.attrsOf (lib.types.either lib.types.lines lib.types.path)) lib.types.path;
      default = { };
      description = ''
        Custom commands for opencode.

        This option can either be:
        - An attribute set defining commands
        - A path to a directory containing multiple command files

        If an attribute set is used, the attribute name becomes the command filename,
        and the value is either:
        - Inline content as a string (creates `opencode/command/<name>.md`)
        - A path to a file (creates `opencode/command/<name>.md`)

        If a path is used, it is expected to contain command files.
        The directory is symlinked to {file}`$XDG_CONFIG_HOME/opencode/command/`.
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
      type = lib.types.either (lib.types.attrsOf (lib.types.either lib.types.lines lib.types.path)) lib.types.path;
      default = { };
      description = ''
        Custom agents for opencode.

        This option can either be:
        - An attribute set defining agents
        - A path to a directory containing multiple agent files

        If an attribute set is used, the attribute name becomes the agent filename,
        and the value is either:
        - Inline content as a string (creates `opencode/agent/<name>.md`)
        - A path to a file (creates `opencode/agent/<name>.md`)

        If a path is used, it is expected to contain agent files.
        The directory is symlinked to {file}`$XDG_CONFIG_HOME/opencode/agent/`.
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

    skills = lib.mkOption {
      type = lib.types.either (lib.types.attrsOf (lib.types.either lib.types.lines lib.types.path)) lib.types.path;
      default = { };
      description = ''
        Custom agent skills for opencode.

        This option can either be:
        - An attribute set defining skills
        - A path to a directory containing multiple skill folders

        If an attribute set is used, the attribute name becomes the skill directory name,
        and the value is either:
        - Inline content as a string (creates `opencode/skill/<name>/SKILL.md`)
        - A path to a file (creates `opencode/skill/<name>/SKILL.md`)
        - A path to a directory (creates `opencode/skill/<name>/` with all files)

        If a path is used, it is expected to contain one folder per skill name, each
        containing a {file}`SKILL.md`. The directory is symlinked to
        {file}`$XDG_CONFIG_HOME/opencode/skill/`.

        See <https://opencode.ai/docs/skills/> for the documentation.
      '';
      example = lib.literalExpression ''
        {
          git-release = '''
            ---
            name: git-release
            description: Create consistent releases and changelogs
            ---

            ## What I do

            - Draft release notes from merged PRs
            - Propose a version bump
            - Provide a copy-pasteable `gh release create` command
          ''';

          # A skill can also be a directory containing SKILL.md and other files.
          data-analysis = ./skills/data-analysis;
        }
      '';
    };

    themes = mkOption {
      type = lib.types.either (lib.types.attrsOf (lib.types.either jsonFormat.type lib.types.path)) lib.types.path;
      default = { };
      description = ''
        Custom themes for opencode.

        This option can either be:
        - An attribute set defining themes
        - A path to a directory containing multiple theme files

        If an attribute set is used, the attribute name becomes the theme filename,
        and the value is either:
        - An attribute set that is converted to a JSON file (creates `opencode/themes/<name>.json`)
        - A path to a file (creates `opencode/themes/<name>.json`)

        If a path is used, it is expected to contain theme files.
        The directory is symlinked to {file}`$XDG_CONFIG_HOME/opencode/themes/`.

        Set `programs.opencode.settings.theme` to enable the custom theme.
        See <https://opencode.ai/docs/themes/> for the documentation.
      '';
    };

    tools = lib.mkOption {
      type = lib.types.either (lib.types.attrsOf (lib.types.either lib.types.lines lib.types.path)) lib.types.path;
      default = { };
      description = ''
        Custom tools for opencode.

        This option can either be:
        - An attribute set defining tools
        - A path to a directory containing multiple tool files

        If an attribute set is used, the attribute name becomes the tool filename,
        and the value is either:
        - Inline content as a string (creates `opencode/tool/<name>.ts`)
        - A path to a file (creates `opencode/tool/<name>.ts` or `opencode/tool/<name>.js`)

        If a path is used, it is expected to contain tool files.
        The directory is symlinked to {file}`$XDG_CONFIG_HOME/opencode/tool/`.

        See <https://opencode.ai/docs/tools/> for the documentation.
      '';
      example = lib.literalExpression ''
        {
          database-query = '''
            import { tool } from "@opencode-ai/plugin"

            export default tool({
              description: "Query the project database",
              args: {
                query: tool.schema.string().describe("SQL query to execute"),
              },
              async execute(args) {
                // Your database logic here
                return `Executed query: ''${args.query}`
              },
            })
          ''';

          # Or reference an existing file
          api-client = ./tools/api-client.ts;
        }
      '';
    };
  };

  config = mkIf cfg.enable {
    assertions = [
      {
        assertion = !lib.isPath cfg.commands || lib.pathIsDirectory cfg.commands;
        message = "`programs.opencode.commands` must be a directory when set to a path";
      }
      {
        assertion = !lib.isPath cfg.agents || lib.pathIsDirectory cfg.agents;
        message = "`programs.opencode.agents` must be a directory when set to a path";
      }
      {
        assertion = !lib.isPath cfg.tools || lib.pathIsDirectory cfg.tools;
        message = "`programs.opencode.tools` must be a directory when set to a path";
      }
      {
        assertion = !lib.isPath cfg.skills || lib.pathIsDirectory cfg.skills;
        message = "`programs.opencode.skills` must be a directory when set to a path";
      }
      {
        assertion = !lib.isPath cfg.themes || lib.pathIsDirectory cfg.themes;
        message = "`programs.opencode.themes` must be a directory when set to a path";
      }
    ];

    home.packages = mkIf (cfg.package != null) [ cfg.package ];

    xdg.configFile = {
      "opencode/config.json" = mkIf (cfg.settings != { } || transformedMcpServers != { }) {
        source =
          let
            # Merge MCP servers: transformed servers + user settings, with user settings taking precedence
            mergedMcpServers = transformedMcpServers // (cfg.settings.mcp or { });
            # Merge all settings
            mergedSettings =
              cfg.settings // (lib.optionalAttrs (mergedMcpServers != { }) { mcp = mergedMcpServers; });
          in
          jsonFormat.generate "config.json" (
            {
              "$schema" = "https://opencode.ai/config.json";
            }
            // mergedSettings
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

      "opencode/command" = mkIf (lib.isPath cfg.commands) {
        source = cfg.commands;
        recursive = true;
      };

      "opencode/agent" = mkIf (lib.isPath cfg.agents) {
        source = cfg.agents;
        recursive = true;
      };

      "opencode/tool" = mkIf (lib.isPath cfg.tools) {
        source = cfg.tools;
        recursive = true;
      };

      "opencode/skill" = mkIf (lib.isPath cfg.skills) {
        source = cfg.skills;
        recursive = true;
      };

      "opencode/themes" = mkIf (lib.isPath cfg.themes) {
        source = cfg.themes;
        recursive = true;
      };
    }
    // lib.optionalAttrs (builtins.isAttrs cfg.commands) (
      lib.mapAttrs' (
        name: content:
        lib.nameValuePair "opencode/command/${name}.md" (
          if lib.isPath content then { source = content; } else { text = content; }
        )
      ) cfg.commands
    )
    // lib.optionalAttrs (builtins.isAttrs cfg.agents) (
      lib.mapAttrs' (
        name: content:
        lib.nameValuePair "opencode/agent/${name}.md" (
          if lib.isPath content then { source = content; } else { text = content; }
        )
      ) cfg.agents
    )
    // lib.optionalAttrs (builtins.isAttrs cfg.tools) (
      lib.mapAttrs' (
        name: content:
        lib.nameValuePair "opencode/tool/${name}.ts" (
          if lib.isPath content then { source = content; } else { text = content; }
        )
      ) cfg.tools
    )
    // lib.mapAttrs' (
      name: content:
      if lib.isPath content && lib.pathIsDirectory content then
        lib.nameValuePair "opencode/skill/${name}" {
          source = content;
          recursive = true;
        }
      else
        lib.nameValuePair "opencode/skill/${name}/SKILL.md" (
          if lib.isPath content then { source = content; } else { text = content; }
        )
    ) (if builtins.isAttrs cfg.skills then cfg.skills else { })
    // lib.optionalAttrs (builtins.isAttrs cfg.themes) (
      lib.mapAttrs' (
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
      ) cfg.themes
    );

    systemd.user.services = mkIf webCfg.enable {
      opencode-web = {
        Unit = {
          Description = "OpenCode Web Service";
          After = [ "network.target" ];
        };

        Service = {
          ExecStart = "${lib.getExe cfg.package} web ${lib.escapeShellArgs webCfg.extraArgs}";
          Restart = "always";
          RestartSec = 5;
        };

        Install = {
          WantedBy = [ "default.target" ];
        };
      };
    };

    launchd.agents = mkIf webCfg.enable {
      opencode-web = {
        enable = true;
        config = {
          ProgramArguments = [
            (lib.getExe cfg.package)
            "web"
          ]
          ++ webCfg.extraArgs;
          KeepAlive = {
            Crashed = true;
            SuccessfulExit = false;
          };
          ProcessType = "Background";
          RunAtLoad = true;
        };
      };
    };
  };
}
