{ pkgs, ... }:

{
  time = "2021-06-02T04:24:10+00:00";
  condition = pkgs.stdenv.hostPlatform.isLinux;
  message = ''

    A new module is available: 'services.xidlehook'.
  '';
}
