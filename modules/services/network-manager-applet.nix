{ config, lib, pkgs, ... }:

with lib;

let

  cfg = config.services.network-manager-applet;

in

{
  meta.maintainers = [ maintainers.rycee ];

  options = {
    services.network-manager-applet = {
      enable = mkEnableOption "the Network Manager applet";

      sni = mkOption {
        type = types.bool;
        default = false;
        example = true;
        description = ''
          Start on SNI mode (appindicator support).
        '';
      };
    };
  };

  config = mkIf config.services.network-manager-applet.enable {
    systemd.user.services.network-manager-applet = {
        Unit = {
          Description = "Network Manager applet";
          After = [ "graphical-session-pre.target" ];
          PartOf = [ "graphical-session.target" ];
        };

        Install = {
          WantedBy = [ "graphical-session.target" ];
        };

        Service = {
          ExecStart = "${pkgs.networkmanagerapplet}/bin/nm-applet --sm-disable ${if cfg.sni then "--indicator" else ""}";
        };
    };
  };
}
