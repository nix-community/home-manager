{ config, lib, pkgs, ... }:

with lib;

let cfg = config.services.autorandr;

in {

  meta.maintainers = [ maintainers.GaetanLepage ];

  options = {
    services.autorandr = {
      enable = mkEnableOption "" // {
        description = ''
          Whether to enable the Autorandr systemd service.
          This module is complementary to <code>programs.autorandr</code> which handles the
          configuration (profiles).
        '';
      };

      ignoreLid = mkOption {
        default = false;
        type = types.bool;
        description =
          "Treat outputs as connected even if their lids are closed.";
      };
    };
  };

  config = mkIf cfg.enable {
    assertions = [
      (lib.hm.assertions.assertPlatform "services.autorandr" pkgs
        lib.platforms.linux)
    ];

    systemd.user.services.autorandr = {
      Unit = {
        Description = "autorandr";
        After = [ "graphical-session-pre.target" ];
        PartOf = [ "graphical-session.target" ];
      };

      Service = {
        Type = "oneshot";
        ExecStart = "${pkgs.autorandr}/bin/autorandr --change ${
            optionalString cfg.ignoreLid "--ignore-lid"
          }";
      };

      Install.WantedBy = [ "graphical-session.target" ];
    };
  };
}
