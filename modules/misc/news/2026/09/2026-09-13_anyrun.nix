{ config, ... }:
{
  time = "2026-09-13T22:59:20+00:00";
  condition = config.programs.anyrun.enable;
  message = ''
    Anyrun now runs as a systemd user daemon by default when
    `programs.anyrun.package` is non-null. Set
    `programs.anyrun.daemon.enable = false` to disable the daemon.

    The module now supports adding extra lines in the main configuration file.
  '';
}
