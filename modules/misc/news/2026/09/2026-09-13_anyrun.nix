{ config, ... }:
{
  time = "2026-09-13T22:59:20+00:00";
  condition = config.programs.anyrun.enable;
  message = ''
    Anyrun now runs as a systemd user daemon by default when
    `programs.anyrun.package` is non-null. Set
    `programs.anyrun.daemon.enable = false` to disable the daemon.

    The `programs.anyrun.config.margin` option has been removed because
    Anyrun no longer supports it. Remove this option from your configuration.

    The module now supports configuring the keyboard mode, navigation keybinds,
    and extra lines in the main configuration file. The default minimum height
    is now 1 instead of 0, matching Anyrun.
  '';
}
