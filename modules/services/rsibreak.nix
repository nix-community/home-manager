{
  config,
  lib,
  pkgs,
  ...
}:

let

  cfg = config.services.rsibreak;

in
{
  options.services.rsibreak = {
    enable = lib.mkEnableOption "rsibreak";

    package = lib.mkPackageOption pkgs "rsibreak" { };
  };

  config = lib.mkIf cfg.enable {
    assertions = [
      (lib.hm.assertions.assertPlatform "services.rsibreak" pkgs lib.platforms.linux)
    ];

    home.packages = [ cfg.package ];
    systemd.user.services.rsibreak = {
      Unit = {
        Description = "RSI break timer";
        After = [ "graphical-session.target" ];
        PartOf = [ "graphical-session.target" ];
      };

      Install = {
        WantedBy = [ "graphical-session.target" ];
      };

      Service = {
        Environment = [ "PATH=${config.home.profileDirectory}/bin" ];
        ExecStart = lib.getExe cfg.package;
      };
    };
  };
}
