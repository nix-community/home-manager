{ config, lib, pkgs, ... }:

with lib;

let

  cfg = config.services.network-manager-applet;

in {
  meta.maintainers = [ maintainers.rycee ];

  options = {
    services.network-manager-applet = {
      enable = mkEnableOption "the Network Manager applet";
    };
  };

  config = mkIf cfg.enable {
    assertions = [
      (lib.hm.assertions.assertPlatform "services.network-manager-applet" pkgs
        lib.platforms.linux)
    ];

    systemd.user.services.network-manager-applet = {
      Unit = {
        Description = "Network Manager applet";
        Requires = [ "tray.target" ];
        After = [ "graphical-session-pre.target" "tray.target" ];
        PartOf = [ "graphical-session.target" ];
      };

      Install = { WantedBy = [ "graphical-session.target" ]; };

      Service = {
        ExecStart = toString
          ([ "${pkgs.networkmanagerapplet}/bin/nm-applet" "--sm-disable" ]
            ++ optional config.xsession.preferStatusNotifierItems
            "--indicator");
      };
    };
  };
}
