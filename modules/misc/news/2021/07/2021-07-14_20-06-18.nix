{ pkgs, ... }:

{
  time = "2021-07-14T20:06:18+00:00";
  condition = pkgs.stdenv.hostPlatform.isLinux;
  message = ''

    A new module is available: 'services.volnoti'.
  '';
}
