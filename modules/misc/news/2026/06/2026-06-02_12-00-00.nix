{ config, ... }:
{
  time = "2026-06-02T12:00:00+00:00";
  condition = config.programs.pi-coding-agent.enable;
  message = ''
    A new module is available: `programs.pi-coding-agent`.

    The module supports declarative configuration of Pi Coding Agent
    including settings, keybindings, models, and global context
    (AGENTS.md).

    For MCP server support, use the existing `programs.mcp` module
    which writes to `~/.config/mcp/mcp.json`.
  '';
}
