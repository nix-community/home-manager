{ pkgs, ... }:

{
  time = "2025-01-30T09:18:55+00:00";
  condition = pkgs.stdenv.hostPlatform.isLinux;
  message = ''
    A new module is available: 'services.linux-wallpaperengine'.

    Reproduce the background functionality of Wallpaper Engine on Linux
    systems.
  '';
}
