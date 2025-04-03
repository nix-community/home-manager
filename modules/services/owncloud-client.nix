{
  config,
  lib,
  pkgs,
  ...
}:
let

  cfg = config.services.owncloud-client;

in
{
  options = {
    services.owncloud-client = {
      enable = lib.mkEnableOption "Owncloud Client";

      package = lib.mkPackageOption pkgs "owncloud-client" { };
    };
  };

  config = lib.mkIf cfg.enable {
    assertions = [
      (lib.hm.assertions.assertPlatform "services.owncloud-client" pkgs lib.platforms.linux)
    ];

    systemd.user.services.owncloud-client = {
      Unit = {
        Description = "Owncloud Client";
        After = [ "graphical-session.target" ];
        PartOf = [ "graphical-session.target" ];
      };

      Service = {
        Environment = [ "PATH=${config.home.profileDirectory}/bin" ];
        ExecStart = "${cfg.package}/bin/owncloud";
      };

      Install = {
        WantedBy = [ "graphical-session.target" ];
      };
    };
  };
}
