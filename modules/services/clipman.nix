{ config, lib, pkgs, ... }:
with lib;
let cfg = config.services.clipman;
in {
  meta.maintainers = [ maintainers.jwygoda ];

  options.services.clipman = {
    enable = mkEnableOption "clipman, a simple clipboard manager for Wayland";

    package = mkPackageOption pkgs "clipman" { };

    systemdTarget = mkOption {
      type = types.str;
      default = config.wayland.systemd.target;
      defaultText = literalExpression "config.wayland.systemd.target";
      example = "sway-session.target";
      description = ''
        The systemd target that will automatically start the clipman service.

        When setting this value to `"sway-session.target"`,
        make sure to also enable {option}`wayland.windowManager.sway.systemd.enable`,
        otherwise the service may never be started.
      '';
    };
  };

  config = mkIf cfg.enable {
    assertions = [
      (lib.hm.assertions.assertPlatform "services.clipman" pkgs
        lib.platforms.linux)
    ];

    home.packages = [ cfg.package ];

    systemd.user.services.clipman = {
      Unit = {
        Description = "Clipboard management daemon";
        PartOf = [ cfg.systemdTarget ];
        After = [ cfg.systemdTarget ];
        ConditionEnvironment = "WAYLAND_DISPLAY";
      };

      Service = {
        ExecStart =
          "${pkgs.wl-clipboard}/bin/wl-paste -t text --watch ${cfg.package}/bin/clipman store";
        ExecReload = "${pkgs.coreutils}/bin/kill -SIGUSR2 $MAINPID";
        Restart = "on-failure";
        KillMode = "mixed";
      };

      Install = { WantedBy = [ cfg.systemdTarget ]; };
    };
  };
}
