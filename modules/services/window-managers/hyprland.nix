{
  # NOTE: Keep this compatibility shim so external flakes using disabledModules
  # with the old hyprland.nix path can still disable the module. See
  # https://github.com/nix-community/home-manager/pull/7304 and
  # https://github.com/hyprland-community/hyprnix.
  imports = [ ./hyprland ];
}
