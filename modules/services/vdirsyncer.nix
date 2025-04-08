{
  config,
  lib,
  pkgs,
  ...
}:

with lib;

let

  cfg = config.services.vdirsyncer;

  vdirsyncerOptions =
    [ ]
    ++ optional (cfg.verbosity != null) "--verbosity ${cfg.verbosity}"
    ++ optional (cfg.configFile != null) "--config ${cfg.configFile}";

in
{
  meta.maintainers = [ maintainers.pjones ];

  options.services.vdirsyncer = {
    enable = mkEnableOption "vdirsyncer";

    package = mkOption {
      type = types.package;
      default = pkgs.vdirsyncer;
      defaultText = "pkgs.vdirsyncer";
      example = literalExpression "pkgs.vdirsyncer";
      description = "The package to use for the vdirsyncer binary.";
    };

    frequency = mkOption {
      type = types.str;
      default = "*:0/5";
      description = ''
        How often to run vdirsyncer.  This value is passed to the systemd
        timer configuration as the onCalendar option.  See
        {manpage}`systemd.time(7)`
        for more information about the format.
      '';
    };

    verbosity = mkOption {
      type = types.nullOr (
        types.enum [
          "CRITICAL"
          "ERROR"
          "WARNING"
          "INFO"
          "DEBUG"
        ]
      );
      default = null;
      description = ''
        Whether vdirsyncer should produce verbose output.
      '';
    };

    configFile = mkOption {
      type = types.nullOr types.path;
      default = null;
      description = ''
        Optional configuration file to link to use instead of
        the default file ({file}`$XDG_CONFIG_HOME/vdirsyncer/config`).
      '';
    };
  };

  config = mkIf cfg.enable {
    systemd.user.services.vdirsyncer = {
      Unit = {
        Description = "vdirsyncer calendar&contacts synchronization";
        PartOf = [ "network-online.target" ];
      };

      Service = {
        Type = "oneshot";
        # TODO `vdirsyncer discover`
        ExecStart =
          let
            optStr = concatStringsSep " " vdirsyncerOptions;
          in
          [
            "${cfg.package}/bin/vdirsyncer ${optStr} metasync"
            "${cfg.package}/bin/vdirsyncer ${optStr} sync"
          ];
      };
    };

    systemd.user.timers.vdirsyncer = {
      Unit = {
        Description = "vdirsyncer calendar&contacts synchronization";
      };

      Timer = {
        OnCalendar = cfg.frequency;
        Unit = "vdirsyncer.service";
      };

      Install = {
        WantedBy = [ "timers.target" ];
      };
    };
  };
}
