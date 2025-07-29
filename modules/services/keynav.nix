{
  config,
  lib,
  pkgs,
  ...
}:
let

  cfg = config.services.keynav;

in
{
  options.services.keynav = {
    enable = lib.mkEnableOption "keynav";

    package = lib.mkPackageOption pkgs "keynav" { };
  };

  config = lib.mkIf cfg.enable {
    assertions = [
      (lib.hm.assertions.assertPlatform "services.keynav" pkgs lib.platforms.linux)
    ];

    systemd.user.services.keynav = {
      Unit = {
        Description = "keynav";
        After = [ "graphical-session.target" ];
        PartOf = [ "graphical-session.target" ];
      };

      Service = {
        ExecStart = lib.getExe cfg.package;
        RestartSec = 3;
        Restart = "always";
      };

      Install = {
        WantedBy = [ "graphical-session.target" ];
      };
    };
  };
}
