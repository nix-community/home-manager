{ config, lib, pkgs, ... }:

with lib;

let

  cfg = config.services.psd;

in {
  meta.maintainers = [ maintainers.danjujan ];

  options.services.psd = {
    enable = mkEnableOption "Profile-sync-daemon service";
    resyncTimer = mkOption {
      type = types.str;
      default = "1h";
      example = "1h 30min";
      description = ''
        The amount of time to wait before syncing browser profiles back to the
        disk.

        Takes a systemd.unit time span. The time unit defaults to seconds if
        omitted.
      '';
    };
  };

  config = mkIf cfg.enable {
    assertions = [
      (lib.hm.assertions.assertPlatform "services.psd" pkgs lib.platforms.linux)
    ];

    home.packages = [ pkgs.profile-sync-daemon ];

    systemd.user = {
      services = {
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
            ExecStart =
              "${pkgs.profile-sync-daemon}/bin/profile-sync-daemon startup";
            ExecStop =
              "${pkgs.profile-sync-daemon}/bin/profile-sync-daemon unsync";
            Environment = [
              "LAUNCHED_BY_SYSTEMD=1"
              "PATH=$PATH:${
                lib.makeBinPath (with pkgs; [
                  rsync
                  kmod
                  gawk
                  nettools
                  util-linux
                  profile-sync-daemon
                ])
              }"
            ];
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
            ExecStart =
              "${pkgs.profile-sync-daemon}/bin/profile-sync-daemon resync";
            Environment = [
              "PATH=$PATH:${
                lib.makeBinPath (with pkgs; [
                  rsync
                  kmod
                  gawk
                  nettools
                  util-linux
                  profile-sync-daemon
                ])
              }"
            ];
          };
          Install = { WantedBy = [ "default.target" ]; };
        };
      };

      timers.psd-resync = {
        Unit = {
          Description = "Timer for Profile-sync-daemon";
          PartOf = [ "psd-resync.service" "psd.service" ];
        };
        Timer = { OnUnitActiveSec = "${cfg.resyncTimer}"; };
      };
    };
  };
}
