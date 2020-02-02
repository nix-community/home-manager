{ config, lib, pkgs, ... }:

with lib;

{
  options = {
    services.nextcloud-client = { enable = mkEnableOption "Nextcloud Client"; };
  };

  config = mkIf config.services.nextcloud-client.enable {
    systemd.user.services.nextcloud-client = {
      Unit = {
        Description = "Nextcloud Client";
        After = [ "graphical-session-pre.target" ];
        PartOf = [ "graphical-session.target" ];
      };

      Service = {
        Environment = "PATH=${config.home.profileDirectory}/bin";
        ExecStart = "${pkgs.nextcloud-client}/bin/nextcloud";
      };

      Install = { WantedBy = [ "graphical-session.target" ]; };
    };
  };
}
