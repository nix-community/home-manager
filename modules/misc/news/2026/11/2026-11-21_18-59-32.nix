{ pkgs, ... }:
{
  time = "2026-11-22T00:59:32+00:00";
  condition = pkgs.stdenv.hostPlatform.isLinux;
  message = ''
    The `programs.wayprompt` module has been removed.

    Nixpkgs removed the `wayprompt` package because it failed to build and
    lacks upstream maintenance.
  '';
}
