{ config, lib, pkgs, ... }:

with lib;

let

  cfg = config.services.screen-locker;

in {

  options.services.screen-locker = {
    enable = mkEnableOption "screen locker for X session";

    lockCmd = mkOption {
      type = types.str;
      description = "Locker command to run.";
      example = "\${pkgs.i3lock}/bin/i3lock -n -c 000000";
    };

    inactiveInterval = mkOption {
      type = types.int;
      default = 10;
      description = ''
        Inactive time interval in minutes after which session will be locked.
        The minimum is 1 minute, and the maximum is 1 hour.
        See <link xlink:href="https://linux.die.net/man/1/xautolock"/>.
      '';
    };

    xautolockExtraOptions = mkOption {
      type = types.listOf types.str;
      default = [];
      description = ''
        Extra command-line arguments to pass to <command>xautolock</command>.
      '';
    };

    xssLockExtraOptions = mkOption {
      type = types.listOf types.str;
      default = [];
      description = ''
        Extra command-line arguments to pass to <command>xss-lock</command>.
      '';
    };

  };

  config = mkIf cfg.enable {
    systemd.user.services.xautolock-session = {
      Unit = {
        Description = "xautolock, session locker service";
        After = [ "graphical-session-pre.target" ];
        PartOf = [ "graphical-session.target" ];
      };

      Install = {
        WantedBy = [ "graphical-session.target" ];
      };

      Service = {
        ExecStart = concatStringsSep " " ([
          "${pkgs.xautolock}/bin/xautolock"
          "-detectsleep"
          "-time ${toString cfg.inactiveInterval}"
          "-locker '${pkgs.systemd}/bin/loginctl lock-session $XDG_SESSION_ID'"
        ] ++ cfg.xautolockExtraOptions);
      };
    };

    # xss-lock will run specified screen locker when the session is locked via loginctl
    # can't be started as a systemd service,
    # see https://bitbucket.org/raymonad/xss-lock/issues/13/allow-operation-as-systemd-user-unit
    xsession.initExtra = "${pkgs.xss-lock}/bin/xss-lock ${concatStringsSep " " cfg.xssLockExtraOptions} -- ${cfg.lockCmd} &";
  };

}
