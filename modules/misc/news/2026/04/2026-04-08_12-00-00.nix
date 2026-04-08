{ config, ... }:
{
  time = "2026-04-08T12:00:00+00:00";
  condition =
    config.programs.claude-code.enable
    || config.programs.codex.enable
    || config.programs.opencode.enable
    || config.programs.gemini-cli.enable;
  message = ''
    The Claude Code, Codex, and OpenCode modules now expose a canonical
    `context` option for configuring their global assistant instructions.

    The old option names still work for now and emit migration warnings:
    - `programs.claude-code.memory.text` and `programs.claude-code.memory.source`
      were changed to `programs.claude-code.context`
    - `programs.codex.custom-instructions` was renamed to
      `programs.codex.context`
    - `programs.opencode.rules` was renamed to `programs.opencode.context`

    Claude Code skills were also unified with the other assistant modules:
    `programs.claude-code.skills` now accepts either an attribute set or a
    directory path, and `programs.claude-code.skillsDir` was changed to
    `programs.claude-code.skills`.

    The `programs.gemini-cli.skills` option now also accepts a directory
    path, matching the bulk skill-directory workflow supported by the
    other assistant modules.
  '';
}
