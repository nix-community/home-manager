{ pkgs, ... }:
{
  time = "2025-10-11T14:06:00+00:00";
  condition = pkgs.stdenv.hostPlatform.isLinux;
  message = ''
    A new service is available: 'services.autotiling'.
    autotiling is a script for Sway and i3 to automatically switch the horizontal / vertical window split orientation.
  '';
}
