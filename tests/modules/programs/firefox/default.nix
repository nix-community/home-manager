{ lib, ... }:
{
  "firefox-bookmarks-legacy-warning" = ./bookmarks-legacy-warning.nix;
  "firefox-bookmarks-legacy-attrset-warning" = ./bookmarks-legacy-attrset-warning.nix;
  "firefox-config-path-explicit-legacy" = ./config-path-explicit-legacy.nix;
  "firefox-config-path-explicit-xdg" = ./config-path-explicit-xdg.nix;
  "firefox-config-path-darwin-default-current" = import ./config-path-darwin-default.nix {
    expectedDarwinPath = "Library/Application Support/org.nixos.firefox";
    stateVersion = "26.11";
  };
  "firefox-config-path-darwin-default-legacy" = import ./config-path-darwin-default.nix {
    expectedDarwinPath = "Library/Application Support/Firefox";
    stateVersion = "26.05";
  };
  "firefox-config-path-darwin-default-null-package" = import ./config-path-darwin-default.nix {
    expectedDarwinPath = "Library/Application Support/Firefox";
    packageIsNull = true;
    stateVersion = "26.11";
  };
  "firefox-config-path-wrapper-absolute" = import ./config-path-wrapper.nix {
    absolute = true;
    configPath = "Library/Application Support/org.nixos.firefox";
  };
  "firefox-config-path-wrapper-relative" = import ./config-path-wrapper.nix {
    configPath = "Library/Application Support/org.nixos.firefox";
  };
  "firefox-config-path-wrapper-unsupported" = import ./config-path-wrapper.nix {
    configPath = "Library/Application Support/org.nixos.firefox";
    supportsAppDataDir = false;
  };
  "firefox-config-path-xdg-default" = ./config-path-xdg-default.nix;
  "firefox-config-path-warning" = ./config-path-warning.nix;
  "firefox-multiple-derivatives" = ./multiple-derivatives.nix;
}
// (import ./firefox.nix { inherit lib; })
// (import ./floorp.nix { inherit lib; })
// (import ./librewolf.nix { inherit lib; })
