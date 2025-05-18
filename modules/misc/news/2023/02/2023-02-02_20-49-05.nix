{ pkgs, ... }:

{
  time = "2023-02-02T20:49:05+00:00";
  condition = pkgs.stdenv.hostPlatform.isLinux;
  message = ''

    A new module is available: 'services.autorandr'.
  '';
}
