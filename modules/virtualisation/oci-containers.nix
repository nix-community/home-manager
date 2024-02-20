# Equivalent of
# https://github.com/NixOS/nixpkgs/blob/nixos-unstable/nixos/modules/virtualisation/oci-containers.nix
{ config, lib, pkgs, ... }:

let
  cfg = config.virtualisation.oci-containers;

  inherit (lib) mkDefault mkIf mkMerge mkOption types;

  defaultBackend = "podman";
in {
  meta.maintainers = [ pkgs.lib.maintainers.michaelCTS ];

  options.virtualisation.oci-containers = {
    enable = lib.mkEnableOption
      "a convenience option to enable containers in platform-agnostic manner";

    backend = mkOption {
      type = types.enum [ "podman" ];
      default = defaultBackend;
      description = "Which service to use as a backend for containers.";
    };
  };

  config = mkIf (cfg.enable && cfg.backend == "podman") {
    virtualisation.podman.enable = true;
  };
}
