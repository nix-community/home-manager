{ config, lib, pkgs, ... }:

with lib;

{
  options = {
    services.dunst = {
      enable = mkEnableOption "the dunst notification daemon";

      settings = mkOption {
        type = types.attrs;
        default = {};
        description = "Configuration written to ~/.config/dunstrc";
      };
    };
  };

  config = mkIf config.services.dunst.enable {
    systemd.user.services.dunst = {
        Unit = {
          Description = "Dunst notification daemon";
        };

        Install = {
          WantedBy = [ "graphical-session.target" ];
        };

        Service = {
          # Type = "dbus";
          # BusName = "org.freedesktop.Notifications";
          ExecStart = "${pkgs.dunst}/bin/dunst";
        };
    };
  };
}
