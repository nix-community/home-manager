{ config, lib, pkgs, ... }:

with lib;

let

  cfg = config.services.megasync;

in {
  meta.maintainers = [ maintainers.GaetanLepage ];

  options = {
    services.megasync = {
      enable = mkEnableOption "Megasync client";

      package = mkPackageOption pkgs "megasync" { };
    };
  };

  config = mkIf cfg.enable {
    assertions = [
      (lib.hm.assertions.assertPlatform "services.megasync" pkgs
        lib.platforms.linux)
    ];

    home.packages = [ cfg.package ];

    systemd.user.services.megasync = {
      Unit = {
        Description = "megasync";
        After = [ "graphical-session-pre.target" ];
        PartOf = [ "graphical-session.target" ];
      };

      Install = { WantedBy = [ "graphical-session.target" ]; };

      Service = { ExecStart = "${cfg.package}/bin/megasync"; };
    };
  };
}
