{ config, ... }:
{
  time = "2026-05-22T20:55:03+00:00";
  condition = config.programs.mcp.enable;
  message = ''
    The {option}`programs.mcp.servers` schema is now typed.

    Instead of freeform JSON objects, structured options are used:
    {option}`command` and {option}`args` for local servers,
    {option}`url` for remote servers,
    {option}`env` for environment variables.

    Environment variables can be specified as literal strings or as file
    references that are read at startup:

    ```nix
    env.API_KEY = "literal";
    env.SESSION_TOKEN.file = "/run/secrets/token";
    ```

    The {var}`lib.hm.mcp` library provides helpers for transforming MCP
    server configurations and is used by opencode, claude-code, codex,
    antigravity-cli, zed-editor, and vscode for MCP integration.
  '';
}
