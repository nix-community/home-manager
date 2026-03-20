{ pkgs, ... }:
{
  time = "2025-05-24T18:18:40+00:00";
  condition = pkgs.stdenv.hostPlatform.isLinux;
  message = ''
    A new module is available: `services.wayvnc`

    wayvnc is a VNC server for wlroots based Wayland compositors.
  '';
}
