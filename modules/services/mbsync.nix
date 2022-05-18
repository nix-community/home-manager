{ config, options, lib, pkgs, ... }:

with lib;

let

  cfg = config.services.mbsync;

  mbsyncOptions = [ "--all" ] ++ optional (cfg.verbose) "--verbose"
    ++ optional (cfg.configFile != null) "--config ${cfg.configFile}";

  inherit (pkgs.stdenv.hostPlatform) isDarwin isLinux;
in {
  meta.maintainers = [ maintainers.pjones maintainers.ryantking ];

  options.services.mbsync = {
    enable = mkEnableOption "mbsync";

    package = mkOption {
      type = types.package;
      default = pkgs.isync;
      defaultText = literalExpression "pkgs.isync";
      example = literalExpression "pkgs.isync";
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

        This does not have any affect on Darwin launchd services.
      '';
    };

    postExec = mkOption {
      type = types.nullOr types.str;
      default = null;
      example = "\${pkgs.mu}/bin/mu index";
      description = ''
        An optional command to run after mbsync executes successfully.
        This is useful for running mailbox indexing tools.

        This does not have any affect on Darwin launchd services.
      '';
    };
  };

  config = mkIf cfg.enable (mkMerge [
    (optionalAttrs (hasAttr "sytemd" options) {
      systemd.user.services.mbsync = {
        Unit = { Description = "mbsync mailbox synchronization"; };

        Service = {
          Type = "oneshot";
          ExecStart =
            "${cfg.package}/bin/mbsync ${concatStringsSep " " mbsyncOptions}";
        } // (optionalAttrs (cfg.postExec != null) {
          ExecStartPost = cfg.postExec;
        }) // (optionalAttrs (cfg.preExec != null) {
          ExecStartPre = cfg.preExec;
        });
      };

      systemd.user.timers.mbsync = {
        Unit = { Description = "mbsync mailbox synchronization"; };

        Timer = {
          OnCalendar = cfg.frequency;
          Unit = "mbsync.service";
        };

        Install = { WantedBy = [ "timers.target" ]; };
      };
    })
    (optionalAttrs (hasAttr "launchd" options) {
      launchd.agents.mbsync = {
        enable = true;
        config = {
          ProgramArguments = let
            startMbsync = pkgs.writeShellScript "start-mbsync" (concatStringsSep "\n" [
              (optionalString (! isNull cfg.preExec) "${cfg.preExec}")
              "${cfg.package}/bin/mbsync ${concatStringsSep " " mbsyncOptions}"
              (optionalString (! isNull cfg.postExec) "${cfg.postExec}")
            ]); in [ "${startMbsync}" ];
          ProcessType = "Adaptive";
          RunAtLoad = true;
          StartInterval = 60 * 15; # TODO(ryantking): Use frequency here... somehow
        };
      };
    })
  ]);
}
