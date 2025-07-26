{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib) mkOption types;

  cfg = config.services.mbsync;

  mbsyncOptions = [
    "--all"
  ]
  ++ lib.optional (cfg.verbose) "--verbose"
  ++ lib.optional (cfg.configFile != null) "--config ${cfg.configFile}";

in
{
  meta.maintainers = [ lib.maintainers.pjones ];

  options.services.mbsync = {
    enable = lib.mkEnableOption "mbsync";

    package = lib.mkPackageOption pkgs "isync" { };

    frequency = mkOption {
      type = types.str;
      default = "*:0/5";
      description = ''
        How often to run mbsync.  This value is passed to the systemd
        timer configuration as the onCalendar option.  See
        {manpage}`systemd.time(7)`
        for more information about the format.
      '';
    };

    verbose = mkOption {
      type = types.bool;
      default = true;
      description = ''
        Whether mbsync should produce verbose output.
      '';
    };

    configFile = mkOption {
      type = types.nullOr types.path;
      default = null;
      description = ''
        Optional configuration file to link to use instead of
        the default file ({file}`~/.mbsyncrc`).
      '';
    };

    preExec = mkOption {
      type = types.nullOr types.str;
      default = null;
      example = "mkdir -p %h/mail";
      description = ''
        An optional command to run before mbsync executes.  This is
        useful for creating the directories mbsync is going to use.
      '';
    };

    postExec = mkOption {
      type = types.nullOr types.str;
      default = null;
      example = "\${pkgs.mu}/bin/mu index";
      description = ''
        An optional command to run after mbsync executes successfully.
        This is useful for running mailbox indexing tools.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    assertions = [
      (lib.hm.assertions.assertPlatform "services.mbsync" pkgs lib.platforms.linux)
    ];

    systemd.user.services.mbsync = {
      Unit = {
        Description = "mbsync mailbox synchronization";
      };

      Service = {
        Type = "oneshot";
        ExecStart = "${cfg.package}/bin/mbsync ${lib.concatStringsSep " " mbsyncOptions}";
      }
      // (lib.optionalAttrs (cfg.postExec != null) {
        ExecStartPost = cfg.postExec;
      })
      // (lib.optionalAttrs (cfg.preExec != null) {
        ExecStartPre = cfg.preExec;
      });
    };

    systemd.user.timers.mbsync = {
      Unit = {
        Description = "mbsync mailbox synchronization";
      };

      Timer = {
        OnCalendar = cfg.frequency;
        Unit = "mbsync.service";
      };

      Install = {
        WantedBy = [ "timers.target" ];
      };
    };
  };
}
