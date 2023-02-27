{ config, lib, pkgs, ... }:

let

  cfg = config.services.copyq;

in {
  meta.maintainers = [ lib.maintainers.DamienCassou ];

  options.services.copyq = {
    enable =
      lib.mkEnableOption "CopyQ, a clipboard manager with advanced features";

    package = lib.mkPackageOption pkgs "copyq" { };

    systemdTarget = lib.mkOption {
      type = lib.types.str;
      default = "graphical-session.target";
      example = "sway-session.target";
      description = ''
        The systemd target that will automatically start the Waybar service.
        </para>
        <para>
        When setting this value to <literal>"sway-session.target"</literal>,
        make sure to also enable <option>wayland.windowManager.sway.systemdIntegration</option>,
        otherwise the service may never be started.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    assertions = [
      (lib.hm.assertions.assertPlatform "services.copyq" pkgs
        lib.platforms.linux)
    ];

    home.packages = [ cfg.package ];

    systemd.user.services.copyq = {
      Unit = {
        Description = "CopyQ clipboard management daemon";
        PartOf = [ "graphical-session.target" ];
        After = [ "graphical-session.target" ];
      };

      Service = {
        ExecStart = "${cfg.package}/bin/copyq";
        Restart = "on-failure";
      };

      Install = { WantedBy = [ cfg.systemdTarget ]; };
    };
  };
}
