{ lib, pkgs, ... }:

lib.optionalAttrs pkgs.stdenv.hostPlatform.isLinux {
  wayle-basic-config = ./basic-config.nix;
  wayle-non-nix-configured = ./non-nix-configured.nix;
  wayle-non-nix-configured-and-no-deps = ./non-nix-configured-and-no-deps.nix;
  wayle-nix-configured-theme-provider = ./nix-configured-theme-provider.nix;
  wayle-nix-configured-theme-provider-and-no-deps = ./nix-configured-theme-provider-and-no-deps.nix;
}
