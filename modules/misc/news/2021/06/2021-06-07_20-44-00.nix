{ pkgs, ... }:

{
  time = "2021-06-07T20:44:00+00:00";
  condition = pkgs.stdenv.hostPlatform.isLinux;
  message = ''

    A new module is available: 'services.pantalaimon'.
  '';
}
