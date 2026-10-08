{ lib, pkgs, ... }:
{
  rclone-basic-configuration = ./basic-configuration.nix;
}
// lib.optionalAttrs pkgs.stdenv.hostPlatform.isLinux {
  rclone-mount-service-generation = ./mount-service-generation.nix;
  rclone-serve-service-generation = ./serve-service-generation.nix;
}
// lib.optionalAttrs pkgs.stdenv.hostPlatform.isDarwin {
  rclone-mount-service-generation-darwin = ./mount-service-generation-darwin.nix;
  rclone-nfsmount-service-generation-darwin = ./nfsmount-service-generation-darwin.nix;
  rclone-serve-service-generation-darwin = ./serve-service-generation-darwin.nix;
}
