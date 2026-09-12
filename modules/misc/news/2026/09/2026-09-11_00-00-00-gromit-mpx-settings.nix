{ config, ... }:

{
  time = "2026-09-11T00:00:00+00:00";
  condition = config.services.gromit-mpx.enable;
  message = ''
    Gromit-MPX now exposes its INI configuration through
    `services.gromit-mpx.iniSettings`. The deprecated
    `services.gromit-mpx.opacity` option remains available as an alias for
    `services.gromit-mpx.iniSettings.Drawing.Opacity`.
  '';
}
