{ pkgs, ... }:
{
  time = "2025-08-18T17:37:24+00:00";
  condition = pkgs.stdenv.hostPlatform.isLinux;
  message = ''
    A new module is available: 'programs.satty'

    Satty is a screenshot annotation tool, inspired by Swappy and Flameshot.
    It can easily integrate with your wlroots based screenshot tool and
    comes with a simple and functional UI for post-processing your screenshots.
  '';
}
