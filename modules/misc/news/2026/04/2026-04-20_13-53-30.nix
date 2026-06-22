{ config, ... }:
{
  time = "2026-04-20T13:53:30+00:00";
  condition = config.programs.rofi.enable;
  message = ''
    The `programs.rofi.extraConfig` option now supports nested attribute sets.
  '';
}
