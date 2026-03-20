{ pkgs, ... }:

{
  time = "2026-01-14T17:05:44+00:00";
  condition = pkgs.stdenv.hostPlatform.isLinux;
  message = ''
    A new module is available: `programs.aphorme`

    A program launcher for window managers, written in Rust.
  '';
}
