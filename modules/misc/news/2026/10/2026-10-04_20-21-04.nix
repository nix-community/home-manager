{ config, ... }:
{
  time = "2026-10-05T01:21:04+00:00";
  condition = config.programs.vesktop.enable;
  message = ''
    Vesktop now supports `programs.vesktop.mutableSettings` and
    `programs.vesktop.vencord.mutableSettings` to keep each settings file
    writable while applying declarative values during activation. Both
    options are disabled by default.
  '';
}
