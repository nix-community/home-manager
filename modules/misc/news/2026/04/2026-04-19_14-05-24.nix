_: {
  time = "2026-04-19T12:05:24+00:00";
  condition = true;
  message = ''
    The {option}`programs.mcp.servers.<name>.envFiles` option has been replaced.
    Use {option}`env.<NAME> = { file = "/path"; }` to load a value from a file at
    startup, and plain string values for literal environment variables.

    The shared {file}`mcp.json` is now written in the de-facto-standard shape
    used by Claude Code, Claude Desktop, Cursor, and others
    ({option}`command` string, {option}`args` list, {option}`env` flat object,
    {option}`type` `"stdio"` or `"http"`). File-backed values render as
    {file}`{file:/path}` substitutions, matching opencode's native syntax;
    clients without that extension see the substitution as a literal string.
  '';
}
