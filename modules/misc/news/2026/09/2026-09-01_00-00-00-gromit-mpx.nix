{ config, pkgs, ... }:

{
  time = "2026-09-01T00:00:00+00:00";
  condition = pkgs.stdenv.hostPlatform.isLinux && config.services.gromit-mpx.enable;
  message = ''
    The `services.gromit-mpx.iniSettings` option now supports additional
    values in the Gromit-MPX INI file. The
    `services.gromit-mpx.cfgSettings` option supports additional values in
    the Gromit-MPX CFG file. The
    `services.gromit-mpx.opacity` option was renamed to
    `services.gromit-mpx.iniSettings.Drawing.Opacity`; existing
    configurations continue to work through compatibility forwarding. The
    `services.gromit-mpx.tools` option remains supported.
  '';
}
