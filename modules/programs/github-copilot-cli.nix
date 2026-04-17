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

  cfg = config.programs.github-copilot-cli;

  jsonFormat = pkgs.formats.json { };

  transformSingleServer =
    _name: server:
    let
      base = removeAttrs server [ "disabled" ];
      withType =
        if base ? type then
          base
        else if base ? url then
          base // { type = "http"; }
        else
          base // { type = "local"; };
      withTools = if withType ? tools then withType else withType // { tools = [ "*" ]; };
    in
    withTools;

  transformedMcpServers =
    if cfg.enableMcpIntegration && config.programs.mcp.enable && config.programs.mcp.servers != { } then
      lib.mapAttrs transformSingleServer (
        lib.filterAttrs (
          _: server: !(server.disabled or false) && (server ? url || server ? command)
        ) config.programs.mcp.servers
      )
    else
      { };

  mergedMcpServers = transformedMcpServers // cfg.mcpServers;
in
{
  meta.maintainers = [ lib.maintainers.ojsef39 ];

  options.programs.github-copilot-cli = {
    enable = mkEnableOption "GitHub Copilot CLI";

    package = mkPackageOption pkgs "github-copilot-cli" { nullable = true; };

    enableMcpIntegration = mkOption {
      type = lib.types.bool;
      default = false;
      description = ''
        Whether to integrate the MCP servers config from
        {option}`programs.mcp.servers` into
        {option}`programs.github-copilot-cli.mcpServers`.

        Servers defined in {option}`programs.mcp.servers` are merged with
        {option}`programs.github-copilot-cli.mcpServers`, with the latter
        taking precedence. Disabled servers (where `disabled = true`) are
        excluded from the generated configuration.
      '';
    };

    settings = mkOption {
      type = lib.types.attrsOf jsonFormat.type;
      default = { };
      example = literalExpression ''
        {
          model = "claude-sonnet-4-5";
          theme = "default";
          trusted_folders = [ "/home/user/projects" ];
          renderMarkdown = true;
          autoUpdate = false;
        }
      '';
      description = ''
        Configuration written to {file}`~/.copilot/config.json`.

        Known configuration keys include:
        - `model` — AI model selection
        - `effortLevel` — reasoning effort for capable models
        - `theme` — `"default"`, `"dim"`, `"high-contrast"`, or `"colorblind"`
        - `mouse` — enable mouse support (default: `true`)
        - `banner` — frequency of animated banner display
        - `renderMarkdown` — markdown rendering toggle (default: `true`)
        - `screenReader` — accessibility optimizations (default: `false`)
        - `autoUpdate` — automatic CLI updates (default: `true`)
        - `stream` — token-by-token response streaming (default: `true`)
        - `includeCoAuthoredBy` — agent commit attribution (default: `true`)
        - `respectGitignore` — exclude gitignored files from file picker
        - `trusted_folders` — list of pre-approved directory paths
        - `allowed_urls`, `denied_urls` — URL allowlists/blocklists
        - `logLevel` — log verbosity
        - `disableAllHooks` — global hook disable toggle
        - `hooks` — inline hook definitions
        - `enabledFeatureFlags` — enable or disable specific feature flags

        See <https://docs.github.com/en/copilot/reference/copilot-cli-reference/cli-config-dir-reference>
        for the documentation.
      '';
    };

    mcpServers = mkOption {
      type = lib.types.attrsOf jsonFormat.type;
      default = { };
      example = literalExpression ''
        {
          playwright = {
            type = "local";
            command = "npx";
            args = [ "@playwright/mcp@latest" ];
            tools = [ "*" ];
          };
          context7 = {
            type = "http";
            url = "https://mcp.context7.com/mcp";
            headers = { CONTEXT7_API_KEY = "YOUR-API-KEY"; };
            tools = [ "*" ];
          };
        }
      '';
      description = ''
        MCP server configurations written to {file}`~/.copilot/mcp-config.json`.

        Each attribute defines a server entry under `mcpServers` in the config
        file. Supported server types:
        - `local` — starts a local process via stdio (`command`, optional `args`, `env`)
        - `http` — connects to a remote HTTP server (`url`, optional `headers`)
        - `sse` — legacy HTTP with Server-Sent Events (same structure as `http`)

        The `tools` field accepts `["*"]` to enable all tools or a list of
        specific tool names.

        See <https://docs.github.com/en/copilot/how-tos/copilot-cli/customize-copilot/add-mcp-servers>
        for the documentation.
      '';
    };
  };

  config = mkIf cfg.enable {
    home.packages = mkIf (cfg.package != null) [ cfg.package ];

    home.file = {
      # NOTE: Copilot will try to add a firstLaunchAt date and crash if the
      # file exists but does not have this key set. Only generate the file when
      # the user has explicitly configured settings, and always inject the
      # default so the managed file stays valid.
      ".copilot/config.json" = mkIf (cfg.settings != { }) {
        source = jsonFormat.generate "github-copilot-cli-config.json" (
          { firstLaunchAt = "1970-01-01T00:00:00.000Z"; } // cfg.settings
        );
      };

      ".copilot/mcp-config.json" = mkIf (mergedMcpServers != { }) {
        source = jsonFormat.generate "github-copilot-cli-mcp-config.json" {
          mcpServers = mergedMcpServers;
        };
      };
    };
  };
}
