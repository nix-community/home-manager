{ pkgs, ... }:

{
  time = "2024-01-27T22:53:00+00:00";
  condition = pkgs.stdenv.hostPlatform.isLinux;
  message = ''

    A new module is available: 'services.wob'.
  '';
}
