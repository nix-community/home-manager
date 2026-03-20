{ pkgs, ... }:

{
  time = "2022-08-25T21:01:37+00:00";
  condition = pkgs.stdenv.hostPlatform.isLinux;
  message = ''

    A new module is available: 'services.pueue'.
  '';
}
