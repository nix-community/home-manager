{ config, lib, pkgs, ... }:

with lib;

let

  cfg = config.services.nextcloud-client;

in {
  options = {
    services.nextcloud-client = {
      enable = mkEnableOption "Nextcloud Client";

      package = mkOption {
        type = types.package;
        default = pkgs.nextcloud-client;
        defaultText = literalExample "pkgs.nextcloud-client";
        description = "The package to use for the nextcloud client binary.";
      };

      runInBackground = mkOption {
        type = types.bool;
        default = false;
        defaultText = literalExample "false";
        description = "Whether to start the Nextcloud client in the background.";
      };
    };
  };

  config = mkIf cfg.enable {
    systemd.user.services.nextcloud-client = {
      Unit = {
        Description = "Nextcloud Client";
        After = [ "graphical-session-pre.target" ];
        PartOf = [ "graphical-session.target" ];
      };

      Service = {
        Environment = "PATH=${config.home.profileDirectory}/bin";
        ExecStart = "${cfg.package}/bin/nextcloud"
          + (if cfg.runInBackground then " --background" else "");
      };

      Install = { WantedBy = [ "graphical-session.target" ]; };
    };
  };
}
