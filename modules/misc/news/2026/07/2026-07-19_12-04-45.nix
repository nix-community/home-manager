{ pkgs, ... }:
{
  time = "2026-07-19T09:04:45+00:00";
  condition = pkgs.stdenv.hostPlatform.isLinux;
  message = ''
    A new module is available: 'programs.dank-material-shell'.
    DankMaterialShell is a complete desktop shell for niri, Hyprland, MangoWC,
    Sway, labwc, Scroll, Miracle WM, and other Wayland compositors. It replaces
    waybar, swaylock, swayidle, mako, fuzzel, polkit, and everything else you'd
    normally stitch together to make a desktop.
  '';
}
