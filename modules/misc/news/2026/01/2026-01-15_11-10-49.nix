{ config, ... }:
{
  time = "2026-01-15T11:10:49+00:00";
  condition = config.programs.codex.enable;
  message = ''
    A new 'programs.codex.skills' option is available to configure Codex
    skills from inline definitions or a directory of skill folders.
  '';
}
