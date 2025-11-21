{ pkgs, ... }:

{
  time = "2021-12-21T22:17:30+00:00";
  condition = pkgs.stdenv.hostPlatform.isLinux;
  message = ''

    A new module is available: 'services.systembus-notify'.
  '';
}
