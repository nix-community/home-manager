{ config, lib, pkgs, ... }:

with lib;

let

  cfg = config.xsession.numlock;

in

{
  options = {
    xsession.numlock.enable = mkEnableOption "Num Lock";
  };

  config = mkIf cfg.enable {
    systemd.user.services.numlockx = {
      Unit = {
        Description = "NumLockX";
        After = [ "graphical-session-pre.target" ];
        PartOf = [ "graphical-session.target" ];
      };

      Service = {
        Type = "oneshot";
        RemainAfterExit = true;
        ExecStart = "${pkgs.numlockx}/bin/numlockx";
      };

      Install = {
        WantedBy = [ "graphical-session.target" ];
      };
    };
  };
}
