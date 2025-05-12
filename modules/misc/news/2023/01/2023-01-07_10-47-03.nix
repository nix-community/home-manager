{ pkgs, ... }:

{
  time = "2023-01-07T10:47:03+00:00";
  condition = pkgs.stdenv.hostPlatform.isLinux;
  message = ''

    'xsession.windowManager.i3.config.[window|floating].titlebar' and
    'wayland.windowManager.sway.config.[window|floating].titlebar' now default to 'true'.
  '';
}
