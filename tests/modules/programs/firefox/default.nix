{
  "firefox-config-path-xdg-default" = ./config-path-xdg-default.nix;
  "firefox-config-path-warning" = ./config-path-warning.nix;
  "firefox-multiple-derivatives" = ./multiple-derivatives.nix;
}
// (import ./firefox.nix)
// (import ./floorp.nix)
// (import ./librewolf.nix)
