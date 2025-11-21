{ pkgs, ... }:

{
  time = "2022-02-17T23:11:13+00:00";
  condition = pkgs.stdenv.hostPlatform.isLinux;
  message = ''

    A new module is available: 'services.espanso'.
  '';
}
