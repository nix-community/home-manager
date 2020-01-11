{ config, lib, pkgs, ... }:

with lib;

let

  cfg = config.services.urxvtd;

in

{
  options = {
    services.urxvtd = {
      enable = mkEnableOption "urxvtd";

      package = mkOption {
        type = types.package;
        default = pkgs.rxvt_unicode;
        defaultText = literalExample "pkgs.rxvt_unicode";
        description = ''
          rxvt-unicode derivation to use.
        '';
      };

    };
  };

  config = mkIf cfg.enable {
    systemd.user.services.urxvtd = {
      Unit = {
        Description = "urxvt terminal daemon";
        After = [ "graphical-session-pre.target" ];
        PartOf = [ "graphical-session.target" ];
      };
      Install = {
        WantedBy = [ "graphical-session.target" ];
      };
      Service = {
        ExecStart = "${cfg.package}/bin/urxvtd -q -o";
        Restart = "on-failure";
        RestartSec = 3;
      };
    };
  };
}
