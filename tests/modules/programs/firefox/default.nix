{ lib, ... }:
{
  "firefox-config-path-explicit-legacy" = ./config-path-explicit-legacy.nix;
  "firefox-config-path-explicit-xdg" = ./config-path-explicit-xdg.nix;
  "firefox-config-path-xdg-default" = ./config-path-xdg-default.nix;
  "firefox-config-path-warning" = ./config-path-warning.nix;
  "firefox-multiple-derivatives" = ./multiple-derivatives.nix;
}
// (import ./firefox.nix { inherit lib; })
// (import ./floorp.nix { inherit lib; })
// (import ./librewolf.nix { inherit lib; })
