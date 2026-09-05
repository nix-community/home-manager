{ pkgs, ... }:
{
  time = "2026-07-04T22:13:18+00:00";
  condition = pkgs.stdenv.hostPlatform.isLinux;
  message = ''
    A new module is available: 'programs.pegasus-frontend'.

    Pegasus-frontend is a cross platform, customizable graphical
    frontend for launching emulators and managing your game collection.
  '';
}
