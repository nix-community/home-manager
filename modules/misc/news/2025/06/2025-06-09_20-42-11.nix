{ pkgs, ... }:
{
  time = "2025-06-09T15:12:11+00:00";
  condition = pkgs.stdenv.hostPlatform.isLinux;
  message = ''
    A new module is available: 'programs.niriswitcher'.

    niriswitcher is an application switcher for niri, with support for
    workspaces and automatic light and dark mode.
  '';
}
