{ pkgs, ... }:

{
  time = "2024-04-19T14:53:17+00:00";
  condition = pkgs.stdenv.hostPlatform.isLinux;
  message = ''

    A new module is available: 'services.remmina'.
  '';
}
