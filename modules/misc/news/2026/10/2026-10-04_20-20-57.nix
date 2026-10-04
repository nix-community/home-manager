{ config, ... }:
{
  time = "2026-10-05T01:20:57+00:00";
  condition = config.programs.antigravity-cli.enable;
  message = ''
    Antigravity CLI now supports `programs.antigravity-cli.mutableSettings`
    to merge declarative settings and MCP servers into writable native
    configuration files during activation. Immutable configuration remains
    the default; legacy Gemini CLI configuration is not supported by this option.
  '';
}
