{ pkgs, ... }:

{
  time = "2025-12-05T01:50:03+00:00";
  condition = pkgs.stdenv.hostPlatform.isLinux;
  message = ''
    A new module is available: `programs.hyprlauncher`

    Hyprlauncher is a multipurpose and versatile launcher/picker
    for hyprland. It’s fast, simple, and provides various modules.
  '';
}
