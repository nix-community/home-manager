{ pkgs, ... }:
{
  time = "2026-03-25T12:00:11+00:00";
  condition = pkgs.stdenv.hostPlatform.isLinux;
  message = ''
    Added a new module `equibop`.

    Equibop is a fork of Vesktop with more plugins.
  '';
}
