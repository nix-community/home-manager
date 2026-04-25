{
  "firefox-config-path-xdg-default" = ./config-path-xdg-default.nix;
  "firefox-config-path-warning" = ./config-path-warning.nix;
  "firefox-multiple-derivatives" = ./multiple-derivatives.nix;
  "librewolf-settings-config-path" = ./librewolf-settings-config-path.nix;
}
// (import ./firefox.nix)
// (import ./floorp.nix)
// (import ./librewolf.nix)
