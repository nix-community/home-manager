{ config, lib, pkgs, ... }:

let

  cfg = config.xsession.numlock;

in {
  meta.maintainers = [ lib.maintainers.evanjs ];

  options = { xsession.numlock.enable = lib.mkEnableOption "Num Lock"; };

  config = lib.mkIf cfg.enable {
    assertions = [
      (lib.hm.assertions.assertPlatform "xsession.numlock" pkgs
        lib.platforms.linux)
    ];

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

      Install = { WantedBy = [ "graphical-session.target" ]; };
    };
  };
}
