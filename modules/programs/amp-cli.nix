{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.programs.amp-cli;
  jsonFormat = pkgs.formats.json { };
  transformedMcpServers = lib.optionalAttrs (cfg.enableMcpIntegration && config.programs.mcp.enable) (
    lib.mapAttrs (
      _name: server:
      (removeAttrs server [ "disabled" ])
      // (lib.optionalAttrs (server ? url) { type = "http"; })
      // (lib.optionalAttrs (server ? command) { type = "stdio"; })
      // {
        enabled = !(server.disabled or false);
      }
    ) config.programs.mcp.servers
  );
  mergedMcpServers = transformedMcpServers // cfg.mcpServers;
  mergedSettings =
    cfg.settings
    // lib.optionalAttrs (mergedMcpServers != { }) {
      "amp.mcpServers" = mergedMcpServers;
    };
in
{
  meta.maintainers = [ ];

  options.programs.amp-cli = {
    enable = lib.mkEnableOption "Amp, Sourcegraph's agentic coding CLI";

    package = lib.mkPackageOption pkgs "amp-cli" { nullable = true; };

    enableMcpIntegration = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = ''
        Whether to integrate the MCP servers config from
        {option}`programs.mcp.servers` into
        {option}`programs.amp-cli.mcpServers`.

        Note: Settings defined in {option}`programs.mcp.servers` are merged
        with {option}`programs.amp-cli.mcpServers`, with Amp CLI servers
        taking precedence.
      '';
    };

    settings = lib.mkOption {
      inherit (jsonFormat) type;
      default = { };
      example = {
        "amp.terminal.theme" = "catppuccin-mocha";
        "amp.notifications.enabled" = true;
        "amp.showCosts" = true;
        "amp.anthropic.thinking.enabled" = true;
        "amp.permissions" = [
          {
            tool = "Bash";
            matches = {
              cmd = "*git commit*";
            };
            action = "ask";
          }
        ];
        "amp.tools.disable" = [ "browser_navigate" ];
        "amp.git.commit.coauthor.enabled" = true;
        "amp.git.commit.ampThread.enabled" = true;
      };
      description = ''
        JSON configuration for Amp CLI settings.json.
        Settings are written to {file}`~/.config/amp/settings.json`.
        All settings use the `amp.` prefix.
        See <https://ampcode.com/manual> for supported values.
      '';
    };

    mcpServers = lib.mkOption {
      type = lib.types.attrsOf jsonFormat.type;
      default = { };
      description = ''
        MCP (Model Context Protocol) servers configuration.
        These are merged into {option}`programs.amp-cli.settings` under
        the `amp.mcpServers` key.
      '';
      example = {
        playwright = {
          command = "npx";
          args = [
            "-y"
            "@playwright/mcp@latest"
            "--headless"
          ];
        };
        linear = {
          url = "https://mcp.linear.app/sse";
        };
        sourcegraph = {
          url = "\${SRC_ENDPOINT}/.api/mcp/v1";
          headers = {
            Authorization = "token \${SRC_ACCESS_TOKEN}";
          };
        };
      };
    };

    agentConfig = lib.mkOption {
      type = lib.types.nullOr lib.types.lines;
      default = null;
      description = ''
        Global agent instructions written to
        {file}`~/.config/amp/AGENTS.md`.
        This provides personal preferences and guidance
        applied to all Amp sessions.
      '';
      example = ''
        # Personal Preferences

        - Always use conventional commits
        - Prefer TypeScript over JavaScript
        - Run tests before committing
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    home.packages = lib.mkIf (cfg.package != null) [ cfg.package ];

    xdg.configFile = {
      "amp/settings.json" = lib.mkIf (mergedSettings != { }) {
        source = jsonFormat.generate "amp-cli-settings.json" mergedSettings;
      };

      "amp/AGENTS.md" = lib.mkIf (cfg.agentConfig != null) {
        text = cfg.agentConfig;
      };
    };
  };
}
