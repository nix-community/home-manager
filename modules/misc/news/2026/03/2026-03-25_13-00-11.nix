{ pkgs, ... }:
{
  time = "2026-03-25T12:00:11+00:00";
  condition = pkgs.stdenv.hostPlatform.isLinux;
  # if behavior changed, explain how to restore previous behavior.
  message = ''
    Added a new module `equibop`.

    Equibop is a fork of Vesktop with more plugins.
  '';
}
