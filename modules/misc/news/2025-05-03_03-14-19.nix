{ pkgs, ... }:

{
  time = "2025-05-03T03:14:19+00:00";
  condition = pkgs.stdenv.hostPlatform.isLinux;
  message = ''
    A new module is available: 'programs.onagre'.

    Onagre is a simple but flexible application launcher for X11 and Wayland.
    Written in Rust, it features fuzzy search, customizable themes, configurable
    keybindings, and supports executing custom commands. Its design philosophy
    focuses on simplicity and efficiency while remaining highly configurable.
  '';
}
