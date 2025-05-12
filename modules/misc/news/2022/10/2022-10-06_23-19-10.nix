{ pkgs, ... }:

{
  time = "2022-10-06T23:19:10+00:00";
  condition = pkgs.stdenv.hostPlatform.isLinux;
  message = ''

    A new module is available: 'programs.havoc'.
  '';
}
