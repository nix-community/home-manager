{ pkgs, ... }:

{
  time = "2025-04-28T03:17:23+00:00";
  condition = pkgs.stdenv.hostPlatform.isLinux;
  message = ''
    A new module is available: 'programs.mpvpaper'.

    mpvpaper is a utility that allows you to use videos or complex animations
    as your desktop wallpaper using mpv. It supports various video formats and
    provides configuration options like framerate limits and scaling methods.
    The module allows you to specify target outputs, video options, and
    additional mpv arguments.
  '';
}
