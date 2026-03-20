{ config, ... }:
{
  time = "2026-01-25T22:41:09+00:00";
  condition = config.programs.opencode.enable;
  message = ''
    A new `programs.opencode.web` option is available to run OpenCode as a
    background web service on Linux (systemd) and macOS (launchd).
  '';
}
