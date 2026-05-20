{ config, ... }:
{
  time = "2026-05-20T12:00:00+00:00";
  condition = config.programs.antigravity-cli.enable;
  message = ''
    The `programs.gemini-cli` module has been renamed to
    `programs.antigravity-cli`.

    Existing `programs.gemini-cli` configurations are migrated automatically
    and emit rename warnings. The Antigravity CLI module writes settings and
    permissions to `~/.gemini/antigravity-cli`, MCP server configuration to
    `~/.gemini/config/mcp_config.json`, and skills to
    `~/.gemini/config/skills`.
  '';
}
