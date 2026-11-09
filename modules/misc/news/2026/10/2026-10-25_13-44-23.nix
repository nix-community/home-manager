{ config, pkgs, ... }:
{
  time = "2026-10-25T11:44:23+00:00";
  condition =
    pkgs.stdenv.hostPlatform.isLinux
    && (
      config.programs.firefox.enable || config.programs.floorp.enable || config.programs.librewolf.enable
    );
  message = ''
    Firefox, Floorp, and LibreWolf profiles now support
    `desktopEntry`, generating an `xdg.desktopEntries` entry that
    launches the browser directly into that profile (`--no-remote -P
    <profile>`), bypassing the profile selector and any
    already-running instance. Disabled by default.
  '';
}
