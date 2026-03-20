{ pkgs, ... }:

{
  time = "2021-08-11T13:55:51+00:00";
  condition = pkgs.stdenv.hostPlatform.isLinux;
  message = ''

    A new module is available: 'services.easyeffects'.
  '';
}
