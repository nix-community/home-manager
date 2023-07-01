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
        defaultText = literalExpression "pkgs.nextcloud-client";
        description = "The package to use for the nextcloud client binary.";
      };

      startInBackground = mkOption {
        type = types.bool;
        default = false;
        description =
          "Whether to start the Nextcloud client in the background.";
      };
    };
  };

  config = mkIf cfg.enable {
    assertions = [
      (lib.hm.assertions.assertPlatform "services.nextcloud-client" pkgs
        lib.platforms.linux)
    ];

    systemd.user.services.nextcloud-client = {
      Unit = {
        Description = "Nextcloud Client";
        After = [ "graphical-session-pre.target" ];
        PartOf = [ "graphical-session.target" ];
      };

      Service = {
        Environment = "PATH=${config.home.profileDirectory}/bin";
        ExecStart = "${cfg.package}/bin/nextcloud"
          + (optionalString cfg.startInBackground " --background");
      };

      Install = { WantedBy = [ "graphical-session.target" ]; };
    };
  };
}
