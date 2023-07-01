{ config, lib, pkgs, ... }:

let

  cfg = config.services.batsignal;

in {
  meta.maintainers = with lib.maintainers; [ kranzes ];

  options = {
    services.batsignal = {
      enable = lib.mkEnableOption "Batsignal Battery Daemon";

      package = lib.mkPackageOption pkgs "batsignal" { };

      extraArgs = lib.mkOption {
        type = with lib.types; listOf str;
        default = [ ];
        description = ''
          Extra arguments to be passed to the batsignal executable.
        '';
      };
    };
  };

  config = lib.mkIf cfg.enable {
    assertions = [
      (lib.hm.assertions.assertPlatform "services.batsignal" pkgs
        lib.platforms.linux)
    ];

    systemd.user.services.batsignal = {
      Unit = {
        Description = "batsignal - battery monitor daemon";
        After = [ "graphical-session-pre.target" ];
        PartOf = [ "graphical-session.target" ];
      };

      Service = {
        Type = "simple";
        ExecStart =
          "${lib.getExe cfg.package} ${lib.escapeShellArgs cfg.extraArgs}";
        Restart = "on-failure";
        RestartSec = 1;
      };

      Install.WantedBy = [ "graphical-session.target" ];
    };
  };
}
