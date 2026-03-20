{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.services.megasync;
in
{
  meta.maintainers = [ lib.maintainers.GaetanLepage ];

  options = {
    services.megasync = {
      enable = lib.mkEnableOption "Megasync client";

      package = lib.mkPackageOption pkgs "megasync" { };

      forceWayland = lib.mkOption {
        type = lib.types.bool;
        default = false;
        example = true;
        description = "Force Megasync to run on wayland";
      };
    };
  };

  config = lib.mkIf cfg.enable {
    assertions = [
      (lib.hm.assertions.assertPlatform "services.megasync" pkgs lib.platforms.linux)
    ];

    home.packages = [ cfg.package ];

    systemd.user.services.megasync = {
      Unit = {
        Description = "megasync";
        After = [ "graphical-session.target" ];
        PartOf = [ "graphical-session.target" ];
      };

      Install = {
        WantedBy = [ "graphical-session.target" ];
      };

      Service = {
        Environment = lib.optionals cfg.forceWayland [ "DO_NOT_UNSET_XDG_SESSION_TYPE=1" ];
        ExecStart = lib.getExe cfg.package;
      };
    };
  };
}
