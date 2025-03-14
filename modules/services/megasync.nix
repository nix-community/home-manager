{ config, lib, pkgs, ... }:
let cfg = config.services.megasync;
in {
  meta.maintainers = [ lib.maintainers.GaetanLepage ];

  options = {
    services.megasync = {
      enable = lib.mkEnableOption "Megasync client";

      package = lib.mkPackageOption pkgs "megasync" { };
    };
  };

  config = lib.mkIf cfg.enable {
    assertions = [
      (lib.hm.assertions.assertPlatform "services.megasync" pkgs
        lib.platforms.linux)
    ];

    home.packages = [ cfg.package ];

    systemd.user.services.megasync = {
      Unit = {
        Description = "megasync";
        After = [ "graphical-session.target" ];
        PartOf = [ "graphical-session.target" ];
      };

      Install = { WantedBy = [ "graphical-session.target" ]; };

      Service = { ExecStart = "${cfg.package}/bin/megasync"; };
    };
  };
}
