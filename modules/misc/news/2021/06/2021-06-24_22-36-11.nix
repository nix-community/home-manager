{ pkgs, ... }:

{
  time = "2021-06-24T22:36:11+00:00";
  condition = pkgs.stdenv.hostPlatform.isLinux;
  message = ''

    A new module is available: 'i18n.inputMethod'.
  '';
}
