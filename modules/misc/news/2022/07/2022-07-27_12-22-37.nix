{ pkgs, ... }:

{
  time = "2022-07-27T12:22:37+00:00";
  condition = pkgs.stdenv.hostPlatform.isLinux;
  message = ''

    A new module is available: 'services.recoll'.
  '';
}
