{ config, lib, pkgs, ... }:

let

  cfg = config.services.amberol;

in {
  meta.maintainers = with lib.maintainers; [ surfaceflinger ];

  options.services.amberol = {
    enable = lib.mkEnableOption "" // {
      description = ''
        Whether to enable Amberol music player as a daemon.

        Note, it is necessary to add
        ```nix
        programs.dconf.enable = true;
        ```
        to your system configuration for the daemon to work correctly.
      '';
    };

    package = lib.mkPackageOption pkgs "amberol" { };

    enableRecoloring = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "UI recoloring using the album art.";
    };

    replaygain = lib.mkOption {
      type = lib.types.enum [ "album" "track" "off" ];
      default = "track";
      description = "ReplayGain mode.";
    };
  };

  config = lib.mkIf cfg.enable {
    assertions = [
      (lib.hm.assertions.assertPlatform "services.amberol" pkgs
        lib.platforms.linux)
    ];

    # Running amberol will just attach itself to gapplication service.
    home.packages = [ cfg.package ];

    dconf.settings."io/bassi/Amberol" = {
      background-play = true;
      enable-recoloring = cfg.enableRecoloring;
      replay-gain = cfg.replaygain;
    };

    systemd.user.services.amberol = {
      Unit = {
        Description = "Amberol music player daemon";
        Requires = [ "dbus.service" ];
        After = [ "graphical-session-pre.target" ];
        PartOf = [ "graphical-session.target" ];
      };

      Install.WantedBy = [ "graphical-session.target" ];

      Service = {
        ExecStart = "${lib.getExe cfg.package} --gapplication-service";
        Restart = "on-failure";
        RestartSec = 5;
      };
    };
  };
}
