{ pkgs, ... }: {
  time = "2026-07-29T02:27:10+00:00";
  condition = pkgs.stdenv.hostPlatform.isLinux;
  message = ''
    A new module is available: 'services.wbg'.

    wbg is a super simple wallpaper application for Wayland compositors.
  '';
}
