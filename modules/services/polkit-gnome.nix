{
  lib,
  pkgs,
  config,
  ...
}: let
  inherit (lib) mkIf mkEnableOption mkOption mkPackageOption;
  cfg = config.services.polkit-gnome;
in {
  meta.maintainers = [];

  options.services.polkit-gnome = {
    enable = mkEnableOption "polkit-gnome";
    package = mkPackageOption pkgs "polkit_gnome";
    systemd = mkEnableOption "systemd service for polkit-gnome" // mkOption {default = true;};
  };

  config = mkIf cfg.enable {
    systemd.user = mkIf cfg.systemd {
      services.polkit-gnome-authentication-agent-1 = {
        description = "polkit-gnome-authentication-agent-1";
        wantedBy = ["graphical-session.target"];
        wants = ["graphical-session.target"];
        after = ["graphical-session.target"];
        serviceConfig = {
          Type = "simple";
          ExecStart = "${pkgs.polkit_gnome}/libexec/polkit-gnome-authentication-agent-1";
          Restart = "on-failure";
          RestartSec = 1;
          TimeoutStopSec = 10;
        };
      };
    };
  };
}
