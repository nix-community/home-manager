{ config, ... }:
{
  time = "2026-10-05T01:21:00+00:00";
  condition = config.programs.pi-coding-agent.enable;
  message = ''
    Pi Coding Agent now supports `programs.pi-coding-agent.mutableSettings`
    to keep `settings.json` writable while applying declarative settings
    during activation. Package entries are matched by package identity,
    preserving other saved entries. Immutable configuration remains the default.
  '';
}
