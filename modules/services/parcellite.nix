{ config, lib, pkgs, ... }:

with lib;

let

  cfg = config.services.parcellite;
  package = pkgs.parcellite;

in

{
  meta.maintainers = [ maintainers.gleber ];

  options = {
    services.parcellite = {
      enable = mkEnableOption "Parcellite";
    };
  };

  config = mkIf cfg.enable {
    home.packages = [ package ];

    systemd.user.services.parcellite = {
      Unit = {
        Description = "Lightweight GTK+ clipboard manager";
        After = [ "graphical-session-pre.target" ];
        PartOf = [ "graphical-session.target" ];
      };

      Install = {
        WantedBy = [ "graphical-session.target" ];
      };

      Service = {
        # PATH have been added in nixpkgs.parcellite, keeping it here for
        # backward compatibility. XDG_DATA_DIRS is necessary to make it pick up
        # icons correctly.
        Environment = ''
          PATH=${package}/bin:${pkgs.which}/bin:${pkgs.xdotool}/bin XDG_DATA_DIRS=${pkgs.hicolor_icon_theme}/share
        '';
        ExecStart = "${package}/bin/parcellite";
        Restart = "on-abort";
      };
    };
  };
}
