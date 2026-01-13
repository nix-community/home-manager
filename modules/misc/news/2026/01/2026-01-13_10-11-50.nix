{ pkgs, ... }:
{
  time = "2026-01-13T01:11:50+00:00";
  condition = pkgs.stdenv.hostPlatform.isLinux;
  message = ''

    Multiple new options are available:

    - services.home-manager.autoUpgrade.flags
    - services.home-manager.autoUpgrade.preSwitchCommands
  '';
}
