{ pkgs, ... }:

{
  time = "2025-09-25T17:32:18+00:00";
  condition = pkgs.stdenv.hostPlatform.isDarwin;
  message = ''
    A new module is available: `programs.desktoppr`

    The module allows declaratively configuring the desktop picture/wallpaper
    on macOS, either once, or on every activation (default), using the
    desktoppr command-line tool.
  '';
}
