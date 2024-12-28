{ config, lib, pkgs, ... }:

let cfg = config.services.trayscale;
in {
  meta.maintainers = [ lib.hm.maintainers.callumio ];

  options.services.trayscale = {
    enable = lib.mkEnableOption
      "An unofficial GUI wrapper around the Tailscale CLI client.";

    package = lib.mkPackageOption pkgs "trayscale" { };

    hideWindow = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Whether to hide the trayscale window on startup.";
    };
  };

  config = lib.mkIf cfg.enable {
    assertions = [
      (lib.hm.assertions.assertPlatform "services.trayscale" pkgs
        lib.platforms.linux)
    ];

    systemd.user.services.trayscale = {
      Unit = {
        Description =
          "An unofficial GUI wrapper around the Tailscale CLI client";
        Requires = [ "tray.target" ];
        After = [ "graphical-session-pre.target" "tray.target" ];
        PartOf = [ "graphical-session.target" ];
      };
      Install = { WantedBy = [ "graphical-session.target" ]; };
      Service.ExecStart = toString ([ "${cfg.package}/bin/trayscale" ]
        ++ lib.optional cfg.hideWindow "--hide-window");
    };
  };
}
