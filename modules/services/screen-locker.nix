{
  config,
  lib,
  pkgs,
  ...
}:

let
  inherit (lib)
    mkIf
    mkRenamedOptionModule
    mkOption
    types
    ;

  cfg = config.services.screen-locker;

in
{
  meta.maintainers = [
    lib.hm.maintainers.jrobsonchase
    lib.hm.maintainers.rszamszur
  ];

  imports =
    let
      origOpt = name: [
        "services"
        "screen-locker"
        name
      ];
      xautolockOpt = name: [
        "services"
        "screen-locker"
        "xautolock"
        name
      ];
      xssLockOpt = name: [
        "services"
        "screen-locker"
        "xss-lock"
        name
      ];
    in
    [
      (mkRenamedOptionModule (origOpt "xssLockExtraOptions") (xssLockOpt "extraOptions"))
      (mkRenamedOptionModule (origOpt "xautolockExtraOptions") (xautolockOpt "extraOptions"))
      (mkRenamedOptionModule (origOpt "enableDetectSleep") (xautolockOpt "detectSleep"))
    ];

  options.services.screen-locker = {
    enable = lib.mkEnableOption "screen locker for X session";

    lockCmd = mkOption {
      type = types.str;
      description = "Locker command to run.";
      example = "\${pkgs.i3lock}/bin/i3lock -n -c 000000";
    };

    lockCmdEnv = lib.mkOption {
      type = types.listOf types.str;
      default = [ ];
      example = [ "XSECURELOCK_PAM_SERVICE=xsecurelock" ];
      description = "Environment variables to source a with the locker command (lockCmd).";
    };

    inactiveInterval = mkOption {
      type = types.int;
      default = 10;
      description = ''
        Inactive time interval in minutes after which session will be locked.
        The minimum is 1 minute, and the maximum is 1 hour.
        If {option}`xautolock.enable` is true, it will use this setting.
        See <https://linux.die.net/man/1/xautolock>.
        Otherwise, this will be used with {command}`xset` to configure
        the X server's screensaver timeout.
      '';
    };

    xautolock = {
      enable = mkOption {
        type = types.bool;
        default = true;
        description = "Use xautolock for time-based locking.";
      };

      package = lib.mkPackageOption pkgs "xautolock" { };

      detectSleep = mkOption {
        type = types.bool;
        default = true;
        description = ''
          Whether to reset xautolock timers when awaking from sleep.
          No effect if {option}`xautolock.enable` is false.
        '';
      };

      extraOptions = mkOption {
        type = types.listOf types.str;
        default = [ ];
        description = ''
          Extra command-line arguments to pass to {command}`xautolock`.
          No effect if {option}`xautolock.enable` is false.
        '';
      };
    };

    xss-lock = {
      package = lib.mkPackageOption pkgs "xss-lock" { };

      extraOptions = mkOption {
        type = types.listOf types.str;
        default = [ ];
        description = ''
          Extra command-line arguments to pass to {command}`xss-lock`.
        '';
      };

      screensaverCycle = mkOption {
        type = types.int;
        default = 600;
        description = ''
          The X server's screensaver cycle value expressed as seconds.
          This will be used with {command}`xset` to configure
          the cycle along with timeout.
        '';
      };
    };
  };

  config = mkIf cfg.enable (
    lib.mkMerge [
      {
        assertions = [
          (lib.hm.assertions.assertPlatform "services.screen-locker" pkgs lib.platforms.linux)
        ];

        systemd.user.services.xss-lock = {
          Unit = {
            Description = "xss-lock, session locker service";
            After = [ "graphical-session.target" ];
            PartOf = [ "graphical-session.target" ];
          };

          Install = {
            WantedBy = [ "graphical-session.target" ];
          };

          Service = {
            ExecStart = lib.concatStringsSep " " (
              [
                "${cfg.xss-lock.package}/bin/xss-lock"
                "-s \${XDG_SESSION_ID}"
              ]
              ++ cfg.xss-lock.extraOptions
              ++ [ "-- ${cfg.lockCmd}" ]
            );
            Environment = cfg.lockCmdEnv;
            Restart = "always";
          };
        };
      }
      (mkIf (!cfg.xautolock.enable) {
        systemd.user.services.xss-lock.Service.ExecStartPre = "${pkgs.xorg.xset}/bin/xset s ${
          toString (cfg.inactiveInterval * 60)
        } ${toString cfg.xss-lock.screensaverCycle}";
      })
      (mkIf cfg.xautolock.enable {
        systemd.user.services.xautolock-session = {
          Unit = {
            Description = "xautolock, session locker service";
            After = [ "graphical-session.target" ];
            PartOf = [ "graphical-session.target" ];
          };

          Install = {
            WantedBy = [ "graphical-session.target" ];
          };

          Service = {
            ExecStart = lib.concatStringsSep " " (
              [
                "${cfg.xautolock.package}/bin/xautolock"
                "-time ${toString cfg.inactiveInterval}"
                "-locker '${pkgs.systemd}/bin/loginctl lock-session \${XDG_SESSION_ID}'"
              ]
              ++ lib.optional cfg.xautolock.detectSleep "-detectsleep"
              ++ cfg.xautolock.extraOptions
            );
            Restart = "always";
          };
        };
      })
    ]
  );
}
