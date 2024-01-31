{ config, lib, pkgs, ... }:

with lib;

let cfg = config.services.osmscout-server;
in {
  meta.maintainers = [ maintainers.Thra11 ];

  options = {
    services.osmscout-server = {
      enable = mkEnableOption "OSM Scout Server";

      package = mkPackageOption pkgs "osmscout-server" { };

      network = {
        startWhenNeeded = mkOption {
          type = types.bool;
          default = true;
          description = ''
            Enable systemd socket activation.
          '';
        };

        listenAddress = mkOption {
          type = types.str;
          default = "127.0.0.1";
          description = ''
            The address for the server to listen on.
          '';
        };

        port = mkOption {
          type = types.port;
          default = 8553;
          description = ''
            The TCP port on which the server will listen.
          '';
        };
      };
    };
  };

  config = mkIf cfg.enable {
    assertions = [
      (lib.hm.assertions.assertPlatform "services.osmscout-server" pkgs
        lib.platforms.linux)
    ];

    systemd.user.services.osmscout-server = {
      Unit = { Description = "OSM Scout Server"; };

      Install = mkIf (!cfg.network.startWhenNeeded) {
        WantedBy = [ "default.target" ];
      };

      Service = {
        ExecStart = "'${cfg.package}/bin/osmscout-server' --systemd --quiet";
      };
    };

    systemd.user.sockets.osmscout-server = mkIf cfg.network.startWhenNeeded {
      Unit = { Description = "OSM Scout Server Socket"; };

      Socket = {
        ListenStream =
          "${cfg.network.listenAddress}:${toString cfg.network.port}";
        TriggerLimitIntervalSec = "60s";
        TriggerLimitBurst = 1;
      };

      Install = { WantedBy = [ "sockets.target" ]; };
    };

    home.packages = [ cfg.package ];
  };
}
