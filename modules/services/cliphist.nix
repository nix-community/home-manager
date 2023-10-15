{ config, lib, pkgs, ... }:
let cfg = config.services.cliphist;
in {
  meta.maintainers = [ lib.maintainers.janik ];

  options.services.cliphist = {
    enable =
      lib.mkEnableOption "cliphist, a clipboard history “manager” for wayland";

    package = lib.mkPackageOption pkgs "cliphist" { };

    systemdTarget = lib.mkOption {
      type = lib.types.str;
      default = "graphical-session.target";
      example = "sway-session.target";
      description = ''
        The systemd target that will automatically start the cliphist service.

        When setting this value to `"sway-session.target"`,
        make sure to also enable {option}`wayland.windowManager.sway.systemd.enable`,
        otherwise the service may never be started.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    assertions = [
      (lib.hm.assertions.assertPlatform "services.cliphist" pkgs
        lib.platforms.linux)
    ];

    home.packages = [ cfg.package ];

    systemd.user.services.cliphist = {
      Unit = {
        Description = "Clipboard management daemon";
        PartOf = [ "graphical-session.target" ];
      };

      Service = {
        Type = "simple";
        ExecStart =
          "${pkgs.wl-clipboard}/bin/wl-paste --watch ${cfg.package}/bin/cliphist store";
        Restart = "on-failure";
      };

      Install = { WantedBy = [ cfg.systemdTarget ]; };
    };
  };
}
