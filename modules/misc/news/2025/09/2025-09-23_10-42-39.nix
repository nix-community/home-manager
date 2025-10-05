{ pkgs, ... }:

{
  time = "2025-09-23T13:42:39+00:00";
  condition = pkgs.stdenv.hostPlatform.isLinux;
  message = ''
    A new module is available: `programs.ahoviewer`

    Ahoviewer is a GTK image viewer, manga reader, and booru browser.
  '';
}
