{
  config,
  lib,
  pkgs,
  ...
}:
{
  meta.maintainers = [ lib.maintainers.philocalyst ];

  options.services.neverest = {
    enable = lib.mkEnableOption "neverest mail synchronization service";

    frequency = lib.mkOption {
      type = lib.types.str;
      default = "hourly";
      example = "*:0/5";
      description = ''
        The interval at which neverest is run.

        On Linux this is passed to the systemd timer as {option}`OnCalendar`.
        See {manpage}`systemd.time(7)` for the format.

        ${lib.hm.darwin.intervalDocumentation}
      '';
    };

    preExec = lib.mkOption {
      type = lib.types.lines;
      default = "";
      example = "mkdir -p ~/mail";
      description = "Shell commands run before each neverest invocation.";
    };

    postExec = lib.mkOption {
      type = lib.types.lines;
      default = "";
      example = "\${pkgs.notmuch}/bin/notmuch new";
      description = "Shell commands run after each successful neverest invocation.";
    };
  };

  config = lib.mkIf config.services.neverest.enable (
    let
      cfg = config.services.neverest;

      # We only need the names of the valid accounts for the script
      accountNames = builtins.attrNames (
        lib.filterAttrs (_: a: a.enable && a.neverest.enable) config.accounts.email.accounts
      );

      useXdg = !pkgs.stdenv.hostPlatform.isDarwin || config.home.preferXdgDirectories;
      configPath =
        if useXdg then
          "${config.xdg.configHome}/neverest/config.toml"
        else
          "${config.home.homeDirectory}/Library/Application Support/neverest/config.toml";

      neverestBin = lib.getExe config.programs.neverest.package;
      confArg = lib.escapeShellArg configPath;

      script = pkgs.writeShellScript "neverest-sync" ''
        ${cfg.preExec}
        ${builtins.concatStringsSep "\n" (
          map (name: "${neverestBin} -c ${confArg} sync ${lib.escapeShellArg name}") accountNames
        )}
        ${cfg.postExec}
      '';
    in
    {
      programs.neverest.enable = true;

      assertions = [
        (lib.hm.darwin.assertInterval "services.neverest.frequency" cfg.frequency pkgs)
      ];

      systemd.user = {
        services.neverest = {
          Unit.Description = "neverest mail synchronization";
          Service = {
            Type = "oneshot";
            Nice = 19;
            IOSchedulingClass = "best-effort";
            IOSchedulingPriority = 7;
            IOWeight = 100;
            Restart = "no";
            LogRateLimitIntervalSec = 0;
            ExecStart = "${script}";
          };
        };

        timers.neverest = {
          Unit.Description = "neverest mail synchronization timer";
          Timer = {
            OnCalendar = cfg.frequency;
            Unit = "neverest.service";
            Persistent = true;
            RandomizedDelaySec = "1m";
          };
          Install.WantedBy = [ "timers.target" ];
        };
      };

      launchd.agents.neverest = {
        enable = true;
        config = {
          ProgramArguments = [ "${script}" ];
          ProcessType = "Background";
          Nice = 19;
          LowPriorityIO = true;
          StartCalendarInterval = lib.hm.darwin.mkCalendarInterval cfg.frequency;
          RunAtLoad = true;
          StandardOutPath = "${config.home.homeDirectory}/Library/Logs/neverest/launchd-stdout.log";
          StandardErrorPath = "${config.home.homeDirectory}/Library/Logs/neverest/launchd-stderr.log";
        };
      };
    }
  );
}
