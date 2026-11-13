{ config, ... }:
{
  time = "2026-10-10T22:42:25+00:00";
  condition =
    config.programs.claude-code.enable
    && config.home.preferXdgDirectories
    && config.programs.claude-code.configDir == "${config.xdg.configHome}/claude";
  message = ''
    `programs.claude-code.configDir` now defaults to
    `''${config.xdg.configHome}/claude` when
    `home.preferXdgDirectories` is true and `home.stateVersion` is at
    least 26.11.

    Existing Claude Code data in `~/.claude` is not migrated automatically.
    Move it to the new directory, or preserve the previous behavior with:

      programs.claude-code.configDir =
        "''${config.home.homeDirectory}/.claude";
  '';
}
