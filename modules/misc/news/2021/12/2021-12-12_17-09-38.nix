{ pkgs, ... }:

{
  time = "2021-12-12T17:09:38+00:00";
  condition = pkgs.stdenv.hostPlatform.isLinux;
  message = ''

    A new module is available: 'services.opensnitch-ui'.
  '';
}
