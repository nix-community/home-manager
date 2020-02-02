{ config, lib, pkgs, ... }:

with lib;

{
  options = {
    services.owncloud-client = { enable = mkEnableOption "Owncloud Client"; };
  };

  config = mkIf config.services.owncloud-client.enable {
    systemd.user.services.owncloud-client = {
      Unit = {
        Description = "Owncloud Client";
        After = [ "graphical-session-pre.target" ];
        PartOf = [ "graphical-session.target" ];
      };

      Service = {
        Environment = "PATH=${config.home.profileDirectory}/bin";
        ExecStart = "${pkgs.owncloud-client}/bin/owncloud";
      };

      Install = { WantedBy = [ "graphical-session.target" ]; };
    };
  };
}
