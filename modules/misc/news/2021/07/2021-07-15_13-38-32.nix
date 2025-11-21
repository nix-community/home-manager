{ pkgs, ... }:

{
  time = "2021-07-15T13:38:32+00:00";
  condition = pkgs.stdenv.hostPlatform.isLinux;
  message = ''

    A new module is available: 'services.xsettingsd'.
  '';
}
