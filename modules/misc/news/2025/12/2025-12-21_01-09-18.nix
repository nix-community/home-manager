{ pkgs, ... }:
{
  time = "2025-12-21T09:09:18+00:00";
  condition = pkgs.stdenv.hostPlatform.isLinux;
  message = ''
    `sunpaper`, a new module for dynamically changing wallpapers based on local sunrise/sunset times, is available.
  '';
}
