{ lib, pkgs, ... }:

lib.optionalAttrs pkgs.stdenv.hostPlatform.isLinux {
  openlinkhub-assert-gamepad = ./assert-gamepad.nix;
  openlinkhub-assert-memory = ./assert-memory.nix;
  openlinkhub-example-configs = ./example-configs.nix;
  openlinkhub-minimal-configs = ./minimal-configs.nix;
  openlinkhub-nested-configs = ./nested-configs.nix;
}
