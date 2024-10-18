{ pkgs, lib, ... }:

with lib;

{
  imports =
    [ ./services.nix ./networks.nix ./containers.nix ./install-quadlet.nix ];

  config = mkIf pkgs.stdenv.isLinux {
    meta.maintainers = [ hm.maintainers.n-hass ];
    assertions =
      [ (hm.assertions.assertPlatform "podman" pkgs platforms.linux) ];
  };
}
