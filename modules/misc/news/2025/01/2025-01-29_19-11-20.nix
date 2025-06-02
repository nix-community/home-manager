{ pkgs, ... }:

{
  time = "2025-01-29T19:11:20+00:00";
  condition = pkgs.stdenv.hostPlatform.isDarwin;
  message = ''
    A new module is available: 'programs.aerospace'.

    AeroSpace is an i3-like tiling window manager for macOS.
    See https://github.com/nikitabobko/AeroSpace for more.
  '';
}
