{ config, ... }:
{
  time = "2026-05-04T20:44:35+00:00";
  condition = config.targets.genericLinux.gpu.enable;
  message = ''
    The GPU driver setup for non-NixOS systems has been switched from
    a systemd service to a tmpfiles.d configuration.

    If you have previously run 'non-nixos-gpu-setup', you will need
    to run it again to migrate. The script will automatically clean
    up the old systemd service and install the new tmpfiles.d config.
  '';
}
