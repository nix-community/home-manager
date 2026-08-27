{ lib, pkgs, ... }:

lib.optionalAttrs pkgs.stdenv.hostPlatform.isDarwin {
  # Disabled for now due to conflicting behavior with nix-darwin. See
  # https://github.com/nix-community/home-manager/issues/1341#issuecomment-687286866
  #targets-darwin = ./darwin.nix;
  terminfo = ./terminfo.nix;
  terminfo-disabled = ./terminfo-disabled.nix;
  terminfo-override = ./terminfo-override.nix;
  user-defaults = ./user-defaults;
  user-defaults-dock = ./user-defaults/dock.nix;
  user-defaults-dock-null-empty = ./user-defaults/dock-null-empty.nix;
  user-defaults-dock-null-empty-reverse = ./user-defaults/dock-null-empty-reverse.nix;
}
