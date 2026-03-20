{ pkgs, ... }:

{
  time = "2022-09-21T22:42:42+00:00";
  condition = pkgs.stdenv.hostPlatform.isLinux;
  message = ''

    A new module is available: 'xsession.windowManager.fluxbox'.
  '';
}
