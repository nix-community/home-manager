{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.services.lakectl-backup;
  inherit (lib)
    getExe
    mkEnableOption
    mkIf
    optionalString
    escapeShellArgs
    escapeShellArg
    mapAttrs'
    mkOption
    concatMapStringsSep
    mkPackageOption
    nameValuePair
    optionalAttrs
    mapAttrsToList
    types
    ;
in
{
  meta.maintainers = [ lib.maintainers.philocalyst ];

  options.services.lakectl-backup = {
    enable = mkEnableOption "lakectl backup service";

    package = mkPackageOption pkgs "lakectl" { };

    backups = mkOption {
      type = types.attrsOf (
        types.submodule {
          options = {
            paths = mkOption {
              type = types.listOf types.str;
              description = "List of local files or directories to back up.";
              example = [
                "~/Documents"
                "/etc/config"
              ];
            };

            repository = mkOption {
              type = types.str;
              description = "Name of the lakeFS repository.";
              example = "my-data";
            };

            branch = mkOption {
              type = types.str;
              default = "main";
              description = "Target branch in lakeFS.";
            };

            prefix = mkOption {
              type = types.str;
              default = "";
              description = "Prefix in lakeFS where the files will be uploaded.";
            };

            calendar = mkOption {
              type = types.str;
              default = "daily";
              description = ''
                The schedule for the backup.

                On Linux, this is a string as defined by {manpage}`systemd.time(7)`.

                ${lib.hm.darwin.intervalDocumentation}
              '';
            };

            commitMessage = mkOption {
              type = types.str;
              default = "Automated backup [$(date)]";
              description = "Commit message for the backup.";
            };

            extraArgs = mkOption {
              type = types.listOf types.str;
              default = [ ];
              description = "Extra arguments for {command}`lakectl fs upload`.";
            };

            environmentFile = mkOption {
              type = types.nullOr types.path;
              default = null;
              description = ''
                Path to a file containing environment variables (e.g., credentials).
                On Linux, this is passed to {option}`EnvironmentFile`.
                On Darwin and in the wrapper, this file is sourced.
              '';
            };
          };
        }
      );
      default = { };
      description = "Backup configurations.";
    };
  };

  config = mkIf cfg.enable {
    home.packages = mapAttrsToList (
      name: backup:
      pkgs.writeShellScriptBin "lakectl-backup-${name}" ''
        set -e
        ${optionalString (
          backup.environmentFile != null
        ) "source ${escapeShellArg (toString backup.environmentFile)}"}

        echo "Starting lakectl backup for ${name}..."
        ${concatMapStringsSep "\n" (path: ''
          echo "Uploading ${path}..."
          ${escapeShellArgs (
            [
              (getExe cfg.package)
              "fs"
              "upload"
              "--recursive"
            ]
            ++ backup.extraArgs
            ++ [
              path
              "lakefs://${backup.repository}/${backup.branch}/${backup.prefix}"
            ]
          )}
        '') backup.paths}

        echo "Committing changes..."
        ${escapeShellArgs [
          (getExe cfg.package)
          "commit"
          "lakefs://${backup.repository}/${backup.branch}"
          "-m"
          backup.commitMessage
        ]}

        echo "Backup ${name} completed successfully."
      ''
    ) cfg.backups;

    systemd.user.services = mapAttrs' (
      name: backup:
      nameValuePair "lakectl-backup-${name}" {
        Unit.Description = "lakectl backup - ${name}";
        Service = {
          Type = "oneshot";
          ExecStart = "${config.home.profileDirectory}/bin/lakectl-backup-${name}";
        }
        // optionalAttrs (backup.environmentFile != null) {
          EnvironmentFile = toString backup.environmentFile;
        };
      }
    ) cfg.backups;

    systemd.user.timers = mapAttrs' (
      name: backup:
      nameValuePair "lakectl-backup-${name}" {
        Unit.Description = "Timer for lakectl backup - ${name}";
        Timer = {
          OnCalendar = backup.calendar;
          Persistent = true;
        };
        Install.WantedBy = [ "timers.target" ];
      }
    ) cfg.backups;

    launchd.agents = mapAttrs' (
      name: backup:
      nameValuePair "lakectl-backup-${name}" {
        enable = true;
        config = {
          ProgramArguments = [ "${config.home.profileDirectory}/bin/lakectl-backup-${name}" ];
          StartCalendarInterval = lib.hm.darwin.mkCalendarInterval backup.calendar;
          ProcessType = "Background";
          StandardOutPath = "${config.home.homeDirectory}/Library/Logs/lakectl-backup/${name}.log";
          StandardErrorPath = "${config.home.homeDirectory}/Library/Logs/lakectl-backup/${name}.err";
        };
      }
    ) cfg.backups;

    assertions = mapAttrsToList (
      name: backup:
      lib.hm.darwin.assertInterval "services.lakectl-backup.backups.${name}.calendar" backup.calendar pkgs
    ) cfg.backups;
  };
}
