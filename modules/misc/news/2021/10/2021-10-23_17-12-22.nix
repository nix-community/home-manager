{ pkgs, ... }:

{
  time = "2021-10-23T17:12:22+00:00";
  condition = pkgs.stdenv.hostPlatform.isLinux;
  message = ''

    A new module is available: 'programs.hexchat'.
  '';
}
