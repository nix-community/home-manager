{ lib, pkgs, ... }:

{
  prismlauncher-asserts = ./asserts.nix;
  prismlauncher-themes = ./themes.nix;
}
// (lib.optionalAttrs pkgs.stdenv.hostPlatform.isLinux {
  prismlauncher-settings = ./settings.nix;
})
