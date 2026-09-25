{
  hyfetch-settings = import ./settings.nix { };
  hyfetch-settings-no-xdg = import ./settings.nix { xdgEnable = false; };
  hyfetch-settings-custom-xdg = import ./settings.nix { configDir = "custom-config"; };
  hyfetch-empty-settings = import ./empty-settings.nix { };
  hyfetch-empty-settings-no-xdg = import ./empty-settings.nix { xdgEnable = false; };
}
