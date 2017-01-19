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
    home.file.".local/share/dbus-1/services/org.knopwob.dunst.service".source =
      "${pkgs.dunst}/share/dbus-1/services/org.knopwob.dunst.service";

    systemd.user.services.dunst = {
      Unit = {
        Description = "Dunst notification daemon";
        Requires = "graphical-session.target";
        After = "graphical-session.target";
      };

      Service = {
        Type = "dbus";
        BusName = "org.freedesktop.Notifications";
        ExecStart = "${pkgs.dunst}/bin/dunst";
      };
    };
  };
}
