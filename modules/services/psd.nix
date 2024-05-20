{ config, lib, pkgs, ... }:

let

  cfg = config.services.psd;

in {
  meta.maintainers = [ lib.hm.maintainers.danjujan ];

  options.services.psd = {
    enable = lib.mkEnableOption "Profile-sync-daemon service";

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
  };

  config = lib.mkIf cfg.enable {
    assertions = [
      (lib.hm.assertions.assertPlatform "services.psd" pkgs lib.platforms.linux)
    ];

    home.packages = [ pkgs.profile-sync-daemon ];

    systemd.user = {
      services = let
        exe = "${pkgs.profile-sync-daemon}/bin/profile-sync-daemon";
        envPath = lib.makeBinPath (with pkgs; [
          rsync
          kmod
          gawk
          nettools
          util-linux
          profile-sync-daemon
        ]);
      in {
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
            Environment = [ "LAUNCHED_BY_SYSTEMD=1" "PATH=$PATH:${envPath}" ];
          };
          Install = { WantedBy = [ "default.target" ]; };
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
          Install = { WantedBy = [ "default.target" ]; };
        };
      };

      timers.psd-resync = {
        Unit = {
          Description = "Timer for Profile-sync-daemon";
          PartOf = [ "psd-resync.service" "psd.service" ];
        };
        Timer = { OnUnitActiveSec = cfg.resyncTimer; };
      };
    };
  };
}
