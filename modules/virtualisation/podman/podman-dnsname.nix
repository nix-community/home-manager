{ config, lib, pkgs, ... }:
let
  inherit (lib) mkOption mkIf types;

  cfg = config.services.podman;

in {
  meta.maintainers = [ lib.maintainers.MaeIsBad ];
  options = {
    services.podman = {

      defaultNetwork.dnsname.enable = mkOption {
        type = types.bool;
        default = false;
        description = ''
          Enable DNS resolution in the default podman network.
        '';
      };

    };
  };

  config = {
    virtualisation.containers.containersConf.cniPlugins =
      mkIf cfg.defaultNetwork.dnsname.enable [ pkgs.dnsname-cni ];
    services.podman.defaultNetwork.extraPlugins =
      lib.optional cfg.defaultNetwork.dnsname.enable {
        type = "dnsname";
        domainName = "dns.podman";
        capabilities.aliases = true;
      };
  };
}
