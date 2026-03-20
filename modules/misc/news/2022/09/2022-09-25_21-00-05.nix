{ pkgs, ... }:

{
  time = "2022-09-25T21:00:05+00:00";
  condition = pkgs.stdenv.hostPlatform.isLinux;
  message = ''

    A new module is available: 'services.safeeyes'.
  '';
}
