{ config, lib, pkgs, ... }:

with lib;

let

  cfg = config.services.parcellite;
  package = pkgs.parcellite;

in {
  meta.maintainers = [ maintainers.gleber ];

  options = {
    services.parcellite = { enable = mkEnableOption "Parcellite"; };
  };

  config = mkIf cfg.enable {
    home.packages = [ package ];

    systemd.user.services.parcellite = {
      Unit = {
        Description = "Lightweight GTK+ clipboard manager";
        After = [ "graphical-session-pre.target" ];
        PartOf = [ "graphical-session.target" ];
      };

      Install = { WantedBy = [ "graphical-session.target" ]; };

      Service = {
        ExecStart = "${package}/bin/parcellite";
        Restart = "on-abort";
      };
    };
  };
}
