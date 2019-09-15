{ config, lib, pkgs, ... }:

with lib;

let

  cfg = config.services.mbsync;

  mbsyncOptions =
    [ "--all"
    ] ++ optional (cfg.verbose) "--verbose"
      ++ optional (cfg.configFile != null) "--config ${cfg.configFile}";

in

{
  meta.maintainers = [ maintainers.pjones ];

  options.services.mbsync = {
    enable = mkEnableOption "mbsync";

    package = mkOption {
      type = types.package;
      default = pkgs.isync;
      defaultText = literalExample "pkgs.isync";
      example = literalExample "pkgs.isync";
      description = "The package to use for the mbsync binary.";
    };

    frequency = mkOption {
      type = types.str;
      default = "*:0/5";
      description = ''
        How often to run mbsync.  This value is passed to the systemd
        timer configuration as the onCalendar option.  See
        <citerefentry>
          <refentrytitle>systemd.time</refentrytitle>
          <manvolnum>7</manvolnum>
        </citerefentry>
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
        the default file (<filename>~/.mbsyncrc</filename>).
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

  config = mkIf cfg.enable {
    systemd.user.services.mbsync = {
      Unit = {
        Description = "mbsync mailbox synchronization";
      };

      Service = {
        Type = "oneshot";
        ExecStart = "${cfg.package}/bin/mbsync ${concatStringsSep " " mbsyncOptions}";
      } // (optionalAttrs (cfg.postExec != null) { ExecStartPost = cfg.postExec; })
        // (optionalAttrs (cfg.preExec  != null) { ExecStartPre  = cfg.preExec;  });
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
