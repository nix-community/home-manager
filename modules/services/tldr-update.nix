{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.services.tldr-update;
in
{
  meta.maintainers = [ lib.maintainers.PerchunPak ];

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

        On Linux this is a string as defined by {manpage}`systemd.time(7)`.

        ${lib.hm.darwin.intervalDocumentation}
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    systemd.user.services.tldr-update = {
      Unit = {
        Description = "Update tldr CLI cache";
        Documentation = "https://tldr.sh/";
        Wants = [ "network-online.target" ];
        After = [ "network-online.target" ];
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

    assertions = [
      (lib.hm.darwin.assertInterval "services.tldr-update.period" cfg.period pkgs)
    ];

    launchd.agents.tldr-update = {
      enable = true;
      config = {
        ProgramArguments = [
          (lib.getExe cfg.package)
          "--update"
        ];
        StartCalendarInterval = lib.hm.darwin.mkCalendarInterval cfg.period;
      };
    };
  };
}
