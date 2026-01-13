{ pkgs, ... }:
{
  time = "2025-11-08T20:50:07+00:00";
  condition = pkgs.stdenv.hostPlatform.isLinux;
  message = ''
    A new module is available: 'programs.retroarch'.

    RetroArch is a frontend for emulators, game engines, and media players.
    Among other things, it enables you to run classic games on a wide
    range of computers and consoles through its slick graphical interface.
  '';
}
