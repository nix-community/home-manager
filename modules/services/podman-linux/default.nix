{ pkgs, lib, ... }:

with lib;

{
  imports =
    [ ./containers.nix ./install-quadlet.nix ./networks.nix ./services.nix ];

  config = mkIf pkgs.stdenv.isLinux {
    meta.maintainers = [ hm.maintainers.bamhm182 hm.maintainers.n-hass ];
    assertions =
      [ (hm.assertions.assertPlatform "podman" pkgs platforms.linux) ];
  };
}
