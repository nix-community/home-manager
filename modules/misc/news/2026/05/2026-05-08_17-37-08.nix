{ pkgs, ... }:
{
  time = "2026-05-08T12:07:08+00:00";
  condition = pkgs.stdenv.hostPlatform.isLinux;
  message = ''
    A new module is avaiable `programs.wiremix`

    A simple TUI mixer for PipeWire.
  '';
}
