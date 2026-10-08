{ pkgs, ... }:
{
  time = "2026-09-04T09:48:53+00:00";
  condition = pkgs.stdenv.hostPlatform.isDarwin;
  message = ''
    A new module is available `programs.omniwm`.

    OmniWM is a macOS tiling window manager inspired by Niri and
    Hyprland. The module manages its launchd agent and writes its
    `settings.toml` configuration.
  '';
}
