{
  config,
  lib,
  pkgs,
  ...
}:
let

  cfg = config.services.nextcloud-client;

in
{
  options = {
    services.nextcloud-client = {
      enable = lib.mkEnableOption "Nextcloud Client";

      package = lib.mkOption {
        type = lib.types.package;
        default = pkgs.nextcloud-client;
        defaultText = lib.literalExpression "pkgs.nextcloud-client";
        description = "The package to use for the nextcloud client binary.";
      };

      startInBackground = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = "Whether to start the Nextcloud client in the background.";
      };
    };
  };

  config = lib.mkIf cfg.enable {
    assertions = [
      (lib.hm.assertions.assertPlatform "services.nextcloud-client" pkgs lib.platforms.linux)
    ];

    systemd.user.services.nextcloud-client = {
      Unit = {
        Description = "Nextcloud Client";
        After = [ "graphical-session.target" ];
        PartOf = [ "graphical-session.target" ];
      };

      Service = {
        Environment = [ "PATH=${config.home.profileDirectory}/bin" ];
        ExecStart =
          "${cfg.package}/bin/nextcloud" + (lib.optionalString cfg.startInBackground " --background");
      };

      Install = {
        WantedBy = [ "graphical-session.target" ];
      };
    };
  };
}
