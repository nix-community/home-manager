{ pkgs, ... }:

{
  time = "2022-11-02T10:56:14+00:00";
  condition = pkgs.stdenv.hostPlatform.isLinux;
  message = ''

    A new module is available: 'xfconf'.
  '';
}
