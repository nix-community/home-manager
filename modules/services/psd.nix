{
  config,
  lib,
  pkgs,
  ...
}:

let

  cfg = config.services.psd;

  configFile = ''
    ${lib.optionalString (cfg.browsers != [ ]) ''
      BROWSERS=(${lib.concatStringsSep " " cfg.browsers})
    ''}

    USE_BACKUP="${if cfg.useBackup then "yes" else "no"}"
    BACKUP_LIMIT=${builtins.toString cfg.backupLimit}
  '';
in
{
  meta.maintainers = [ lib.hm.maintainers.danjujan ];

  options.services.psd = {
    enable = lib.mkEnableOption "Profile-sync-daemon service";

    package = lib.mkPackageOption pkgs "profile-sync-daemon" { };

    resyncTimer = lib.mkOption {
      type = lib.types.str;
      default = "1h";
      example = "1h 30min";
      description = ''
        The amount of time to wait before syncing browser profiles back to the
        disk.

        Takes a systemd time span, see {manpage}`systemd.time(7)`. The time unit
        defaults to seconds if omitted.
      '';
    };

    browsers = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      example = [
        "chromium"
        "google-chrome"
        "firefox"
      ];
      description = ''
        A list of browsers to sync. An empty list will enable all browsers to be managed by profile-sync-daemon.

        Available choices are:
        chromium chromium-dev conkeror.mozdev.org epiphany falkon firefox firefox-trunk google-chrome google-chrome-beta google-chrome-unstable heftig-aurora icecat inox luakit midori opera opera-beta opera-developer opera-legacy otter-browser qupzilla qutebrowser palemoon rekonq seamonkey surf vivaldi vivaldi-snapshot
      '';
    };

    useBackup = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = ''
        Whether to completly enable or disable the crash recovery feature.
      '';
    };

    backupLimit = lib.mkOption {
      type = lib.types.ints.unsigned;
      default = 5;
      description = ''
        Maximum number of crash recovery snapshots to keep (the oldest ones are deleted first).
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    assertions = [
      (lib.hm.assertions.assertPlatform "services.psd" pkgs lib.platforms.linux)
    ];

    home.packages = [ cfg.package ];

    systemd.user = {
      services =
        let
          exe = lib.getExe' cfg.package "profile-sync-daemon";
          envPath = lib.makeBinPath (
            with pkgs;
            [
              rsync
              kmod
              gawk
              gnugrep
              gnused
              coreutils
              findutils
              nettools
              util-linux
              cfg.package
            ]
          );
        in
        {
          psd = {
            Unit = {
              Description = "Profile-sync-daemon";
              Wants = [ "psd-resync.service" ];
              RequiresMountsFor = [ "/home/" ];
              After = "winbindd.service";
            };
            Service = {
              Type = "oneshot";
              RemainAfterExit = "yes";
              ExecStart = "${exe} startup";
              ExecStop = "${exe} unsync";
              Environment = [
                "LAUNCHED_BY_SYSTEMD=1"
                "PATH=$PATH:${envPath}"
              ];
            };
            Install = {
              WantedBy = [ "default.target" ];
            };
          };

          psd-resync = {
            Unit = {
              Description = "Timed profile resync";
              After = [ "psd.service" ];
              Wants = [ "psd-resync.timer" ];
              PartOf = [ "psd.service" ];
            };
            Service = {
              Type = "oneshot";
              ExecStart = "${exe} resync";
              Environment = [ "PATH=$PATH:${envPath}" ];
            };
            Install = {
              WantedBy = [ "default.target" ];
            };
          };
        };

      timers.psd-resync = {
        Unit = {
          Description = "Timer for Profile-sync-daemon";
          PartOf = [
            "psd-resync.service"
            "psd.service"
          ];
        };
        Timer = {
          OnUnitActiveSec = cfg.resyncTimer;
        };
      };
    };

    xdg.configFile."psd/psd.conf".text = configFile;
  };
}
