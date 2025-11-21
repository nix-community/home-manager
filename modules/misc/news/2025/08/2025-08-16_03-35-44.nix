{ pkgs, ... }:
{
  time = "2025-08-16T01:35:44+00:00";
  condition = pkgs.stdenv.hostPlatform.isLinux;
  message = ''
    A new module is available: 'programs.hyprshot'

    Hyprshot is an utility to easily take screenshot in Hyprland using your mouse.
    It allows taking screenshots of windows, regions and monitors which are saved
    to a folder of your choosing and copied to your clipboard.
  '';
}
