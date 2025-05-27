{ pkgs, ... }:

{
  time = "2022-01-22T16:54:31+00:00";
  condition = pkgs.stdenv.hostPlatform.isLinux;
  message = ''

    A new module is available: 'programs.tint2'.
  '';
}
