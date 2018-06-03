{ config, lib, pkgs, ... }:

with lib;

let

  cfg = config.services.flameshot;
  package = pkgs.flameshot;

in

{
  meta.maintainers = [ maintainers.hamhut1066 ];

  options = {
    services.flameshot = {
      enable = mkEnableOption "Flameshot";
    };
  };

  config = mkIf cfg.enable {
    home.packages = [ package ];

    systemd.user.services.flameshot = {
      Unit = {
        Description = "Powerful yet simple to use screenshot software";
        After = [ "graphical-session-pre.target" ];
        PartOf = [ "graphical-session.target" ];
      };

      Install = {
        WantedBy = [ "graphical-session.target" ];
      };

      Service = {
        Environment = "PATH=${config.qt.systemdServicePath}";
        ExecStart = "${package}/bin/flameshot";
        Restart = "on-abort";
      };
    };
  };
}
