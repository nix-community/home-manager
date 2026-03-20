{ pkgs, ... }:

{
  time = "2022-12-16T15:01:20+00:00";
  condition = pkgs.stdenv.hostPlatform.isLinux;
  message = ''

    A new module is available: 'services.megasync'.
  '';
}
