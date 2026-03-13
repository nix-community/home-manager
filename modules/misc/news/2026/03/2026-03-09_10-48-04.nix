{ config, lib, ... }:
{
  time = "2026-03-09T10:48:04+00:00";
  condition = config.programs.codex.enable && lib.isPath config.programs.codex.skills;
  message = ''
    The `programs.codex.skills` path-backed directory is now symlinked
    into the Codex config directory, matching the option documentation.
  '';
}
