{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.services.autorandr;
in
{
  meta.maintainers = [ lib.maintainers.GaetanLepage ];

  options = {
    services.autorandr = {
      enable = lib.mkEnableOption "" // {
        description = ''
          Whether to enable the Autorandr systemd service.
          This module is complementary to {option}`programs.autorandr`
          which handles the configuration (profiles).
        '';
      };

      ignoreLid = lib.mkOption {
        default = false;
        type = lib.types.bool;
        description = "Treat outputs as connected even if their lids are closed.";
      };
    };
  };

  config = lib.mkIf cfg.enable {
    assertions = [
      (lib.hm.assertions.assertPlatform "services.autorandr" pkgs lib.platforms.linux)
    ];

    systemd.user.services.autorandr = {
      Unit = {
        Description = "autorandr";
        After = [ "graphical-session.target" ];
        PartOf = [ "graphical-session.target" ];
      };

      Service = {
        Type = "oneshot";
        ExecStart = "${pkgs.autorandr}/bin/autorandr --change ${lib.optionalString cfg.ignoreLid "--ignore-lid"}";
      };

      Install.WantedBy = [ "graphical-session.target" ];
    };
  };
}
