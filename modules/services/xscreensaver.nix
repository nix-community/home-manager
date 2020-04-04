{ config, lib, pkgs, ... }:

with lib;

let

  cfg = config.services.xscreensaver;

in {
  meta.maintainers = [ maintainers.rycee ];

  options = {
    services.xscreensaver = {
      enable = mkEnableOption "XScreenSaver";

      settings = mkOption {
        type = with types; attrsOf (either bool (either int str));
        default = { };
        example = {
          mode = "blank";
          lock = false;
          fadeTicks = 20;
        };
        description = ''
          The settings to use for XScreenSaver.
        '';
      };

      command = mkOption {
        type = types.str;
        default = "${pkgs.xscreensaver}/bin/xscreensaver -no-splash";
        example = "${config.home.homeDirectory}/bin/wrapped-xscreensaver";
        description = "Command to start the xscreensaver";
      };
    };
  };

  config = mkIf cfg.enable {
    # To make the xscreensaver-command tool available.
    home.packages = [ pkgs.xscreensaver ];

    xresources.properties =
      mapAttrs' (n: nameValuePair "xscreensaver.${n}") cfg.settings;

    systemd.user.services.xscreensaver = {
      Unit = {
        Description = "XScreenSaver";
        After = [ "graphical-session-pre.target" ];
        PartOf = [ "graphical-session.target" ];
      };

      Service = { ExecStart = services.xscreensaver.command; };

      Install = { WantedBy = [ "graphical-session.target" ]; };
    };
  };
}
