{ config, ... }:
{
  time = "2026-10-05T01:21:07+00:00";
  condition = config.programs.opencode.enable;
  message = ''
    OpenCode now supports `programs.opencode.mutableSettings` to load
    declarative settings from separate read-only files, leaving its main
    configuration files writable. The option is disabled by default.
    Launches outside the web service must receive the Home Manager session
    variables; the TUI configuration layer requires OpenCode 1.2.15 or later.
  '';
}
