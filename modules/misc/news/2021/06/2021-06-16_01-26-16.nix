{ pkgs, ... }:

{
  time = "2021-06-16T01:26:16+00:00";
  condition = pkgs.stdenv.hostPlatform.isLinux;
  message = ''

    The xmonad module now compiles the configuration before
    linking the binary to the place xmonad expects to find
    the compiled configuration (the binary).

    This breaks recompilation of xmonad (i.e. the 'q' binding or
    'xmonad --recompile').

    If this behavior is undesirable, do not use the
    'xsession.windowManager.xmonad.config' option. Instead, set the
    contents of the configuration file with
    'home.file.".xmonad/config.hs".text = "content of the file"'
    or 'home.file.".xmonad/config.hs".source = ./path-to-config'.
  '';
}
