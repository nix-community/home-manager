{ config, pkgs, lib, ... }:

{
  meta.maintainers = with lib.hm.maintainers; [ bamhm182 n-hass ];

  imports =
    [ ./containers.nix ./install-quadlet.nix ./networks.nix ./services.nix ];

  options.services.podman = {
    enable = lib.mkEnableOption "Podman, a daemonless container engine";
  };

  config = lib.mkIf config.services.podman.enable {
    assertions =
      [ (lib.hm.assertions.assertPlatform "podman" pkgs lib.platforms.linux) ];
  };
}
