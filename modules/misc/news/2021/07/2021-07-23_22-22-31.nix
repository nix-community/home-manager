{ pkgs, ... }:

{
  time = "2021-07-23T22:22:31+00:00";
  condition = pkgs.stdenv.hostPlatform.isLinux;
  message = ''

    A new module is available: 'services.trayer'.
  '';
}
