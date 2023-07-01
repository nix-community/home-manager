{ config, lib, pkgs, ... }:

with lib;

let

  cfg = config.services.owncloud-client;

in {
  options = {
    services.owncloud-client = {
      enable = mkEnableOption "Owncloud Client";

      package = mkPackageOption pkgs "owncloud-client" { };
    };
  };

  config = mkIf cfg.enable {
    assertions = [
      (hm.assertions.assertPlatform "services.owncloud-client" pkgs
        platforms.linux)
    ];

    systemd.user.services.owncloud-client = {
      Unit = {
        Description = "Owncloud Client";
        After = [ "graphical-session-pre.target" ];
        PartOf = [ "graphical-session.target" ];
      };

      Service = {
        Environment = "PATH=${config.home.profileDirectory}/bin";
        ExecStart = "${cfg.package}/bin/owncloud";
      };

      Install = { WantedBy = [ "graphical-session.target" ]; };
    };
  };
}
