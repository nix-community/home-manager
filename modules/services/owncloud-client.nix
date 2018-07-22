{ config, lib, pkgs, ... }:

with lib;

let

  profileDir = if config.nixosSubmodule then "${config.home.path}" else "%h/.nix-profile";

in {
  options = {
    services.owncloud-client = {
      enable = mkEnableOption "Owncloud Client";
    };
  };

  config = mkIf config.services.owncloud-client.enable {
    systemd.user.services.owncloud-client = {
      Unit = {
        Description = "Owncloud Client";
        After = [ "graphical-session-pre.target" ];
        PartOf = [ "graphical-session.target" ];
      };

      Service = {
        Environment = "PATH=${profileDir}/bin";
        ExecStart = "${pkgs.owncloud-client}/bin/owncloud";
      };

      Install = {
        WantedBy = [ "graphical-session.target" ];
      };
    };
  };
}
