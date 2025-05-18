{ pkgs, ... }:

{
  time = "2022-07-25T11:29:14+00:00";
  condition = pkgs.stdenv.hostPlatform.isLinux;
  message = ''

    A new module is available: 'xsession.windowManager.spectrwm'.
  '';
}
