{ pkgs, lib, ... }:

with lib;

{
  meta.maintainers = [ maintainers.n-hass ];

  imports =
    [ ./services.nix ./networks.nix ./containers.nix ./install-quadlet.nix ];

  config = {
    assertions =
      [ (lib.hm.assertions.assertPlatform "podman" pkgs lib.platforms.linux) ];
  };
}
