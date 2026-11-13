{ config, pkgs, ... }:
{
  time = "2026-10-02T08:18:56+00:00";
  condition = pkgs.stdenv.hostPlatform.isLinux && config.services.plex-mpv-shim.enable;
  message = ''
    A new option 'services.plex-mpv-shim.mutableSettings' is available.

    When enabled, settings declared through 'services.plex-mpv-shim.settings'
    are merged into a writable 'conf.json' at activation instead of being
    linked from the Nix store. This lets Plex mpv shim save menu changes and
    keep its player identity across restarts. Declared settings override
    existing values, and other keys are preserved, including settings later
    removed from your Home Manager configuration.
  '';
}
