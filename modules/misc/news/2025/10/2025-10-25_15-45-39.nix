{
  time = "2025-10-25T14:45:39+00:00";
  condition = true;
  message = ''
    The home-manager auto-upgrade service now supports updating Nix flakes.

    Enable this by setting `services.home-manager.autoUpgrade.useFlake = true;`.

    The flake directory can be configured with `services.home-manager.autoUpgrade.flakeDir`,
    which defaults to the configured XDG config home (typically `~/.config/home-manager`).
  '';
}
