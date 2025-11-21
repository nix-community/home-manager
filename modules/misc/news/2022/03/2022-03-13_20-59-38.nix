{ pkgs, ... }:

{
  time = "2022-03-13T20:59:38+00:00";
  condition = pkgs.stdenv.hostPlatform.isLinux;
  message = ''

    A new module is available: 'services.fusuma'.
  '';
}
