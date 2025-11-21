{ pkgs, ... }:

{
  time = "2021-08-26T06:40:59+00:00";
  condition = pkgs.stdenv.hostPlatform.isLinux;
  message = ''

    A new module is available: 'services.fnott'.
  '';
}
