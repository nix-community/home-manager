{ pkgs, ... }:

{
  time = "2021-12-31T09:39:20+00:00";
  condition = pkgs.stdenv.hostPlatform.isLinux;
  message = ''

    A new module is available: 'xsession.windowManager.herbstluftwm'.
  '';
}
