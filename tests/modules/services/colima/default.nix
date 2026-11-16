{ lib, pkgs, ... }:
(lib.optionalAttrs pkgs.stdenv.hostPlatform.isDarwin (import ./darwin/default.nix))
// (lib.optionalAttrs pkgs.stdenv.hostPlatform.isLinux (import ./linux/default.nix))

// {
  colima-mutable-settings-legacy = ./mutable-settings-legacy.nix;
  colima-mutable-settings-xdg = ./mutable-settings-xdg.nix;
  colima-mutable-settings-custom = ./mutable-settings-custom.nix;
  colima-mutable-settings-disabled = ./mutable-settings-disabled.nix;
}
