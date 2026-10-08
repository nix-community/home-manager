{ config, ... }:
{
  time = "2026-08-06T01:29:34+00:00";
  # Mirrors the generated-plugin trigger in the module: the plugin is created
  # whenever MCP or LSP servers are produced, including shared MCP servers
  # pulled in via `enableMcpIntegration`, not just direct `mcpServers`.
  condition =
    config.programs.claude-code.enable
    && (
      config.programs.claude-code.enableMcpIntegration
      && config.programs.mcp.enable
      && config.programs.mcp.servers != { }
      || config.programs.claude-code.mcpServers != { }
      || config.programs.claude-code.lspServers != { }
    );
  message = ''
    The generated plugin that delivers managed MCP and LSP configuration to
    Claude Code now uses the manifest name `hm` (previously
    `claude-code-home-manager`). Claude Code derives the MCP tool namespace from
    the plugin manifest, so this shortens every plugin-loaded MCP tool prefix to
    `mcp__plugin_hm_<server>__<tool>`. See
    [issue #9446](https://github.com/nix-community/home-manager/issues/9446).

    The personal skills directory stays `~/.claude/skills/claude-code-home-manager`
    unchanged, so it does not collide with user plugins or skills.

    This is a breaking change. If you allow or deny these tools by name in
    {file}`<project>/.claude/settings.{, local.}json` or via
    {option}`programs.claude-code.settings`, update any references from
    `claude-code-home-manager` to `hm`, for example:

    ```json
    {
      "permissions": {
        "allow": ["mcp__plugin_hm_github"]
      }
    }
    ```
  '';
}
