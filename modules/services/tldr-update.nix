{ config, lib, pkgs, ... }:
let cfg = config.services.tldr-update;
in {
  meta.maintainers = [ lib.maintainers.perchun ];

  options.services.tldr-update = {
    enable = lib.mkEnableOption ''
      Automatic updates for the tldr CLI
    '';

    package = lib.mkPackageOption pkgs "tldr" { example = "tlrc"; };

    period = lib.mkOption {
      type = lib.types.str;
      default = "weekly";
      description = ''
        Systemd timer period to create for scheduled {command}`tldr --update`.

        The format is described in {manpage}`systemd.time(7)`.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    systemd.user.services.tldr-update = {
      Unit = {
        Description = "Update tldr CLI cache";
        Documentation = "https://tldr.sh/";
      };

      Service = {
        Type = "oneshot";
        ExecStart = ''
          ${lib.getExe cfg.package} --update
        '';
      };
    };

    systemd.user.timers.tldr-update = {
      Unit.Description = "Update tldr CLI cache";

      Timer = {
        OnCalendar = cfg.period;
        Persistent = true;
      };

      Install.WantedBy = [ "timers.target" ];
    };
  };
}
