{ lib, pkgs, ... }:
lib.optionalAttrs pkgs.stdenv.hostPlatform.isLinux {
  rclone-basic-configuration = ./basic-configuration.nix;
  rclone-mount-service-generation = ./mount-service-generation.nix;
  rclone-serve-service-generation = ./serve-service-generation.nix;
}
