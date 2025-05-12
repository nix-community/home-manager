{ pkgs, ... }:

{
  time = "2024-04-19T09:23:52+00:00";
  condition = pkgs.stdenv.hostPlatform.isLinux;
  message = ''

    A new module is available: 'programs.tofi'.
  '';
}
