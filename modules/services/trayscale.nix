{ config, lib, pkgs, ... }:
with lib;
let cfg = config.services.trayscale;
in {
  meta.maintainers = [ hm.maintainers.callumio ];

  options.services.trayscale = {
    enable = mkEnableOption
      "An unofficial GUI wrapper around the Tailscale CLI client.";
    package = mkPackageOption pkgs "trayscale" { };
    hideWindow = mkOption {
      description = "Whether to hide the trayscale window on startup.";
      type = types.bool;
      default = true;
    };
  };

  config = mkIf cfg.enable {
    assertions = [
      (hm.assertions.assertPlatform "services.trayscale" pkgs platforms.linux)
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
        ++ optional cfg.hideWindow "--hide-window");
    };
  };
}
