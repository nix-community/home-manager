{ pkgs, ... }:
{
  time = "2026-11-18T11:45:10+00:00";
  condition = pkgs.stdenv.hostPlatform.isLinux;
  message = ''
    A new module is available: 'wayland.windowManager.umbriel'.

    Umbriel is an independent Wayland compositor built on wlroots, with
    scrolling, dwindle and master layouts, blur, shadows and animations. It
    can be paired with the Noctalia desktop shell.

    The module installs Umbriel, its systemd units and the
    xdg-desktop-portal-umbriel backend used for screen capture and sharing.
    Settings are written as TOML to $XDG_CONFIG_HOME/umbriel/config.toml. If
    you leave them empty, Umbriel uses its packaged default configuration.
  '';
}
