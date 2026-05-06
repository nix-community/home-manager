{ lib, pkgs, ... }:
{
  rclone-basic-configuration = ./basic-configuration.nix;
}
// lib.optionalAttrs pkgs.stdenv.hostPlatform.isLinux {
  rclone-mount-service-generation = ./mount-service-generation.nix;
  rclone-serve-service-generation = ./serve-service-generation.nix;
}
