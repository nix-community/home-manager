{
  config,
  lib,
  pkgs,
  ...
}:
let
  unitType =
    with lib.types;
    let
      primitive = oneOf [
        bool
        int
        str
        path
      ];
    in
    attrsOf (either primitive (listOf primitive));

  cfg = config.services.restic;

  fmtRcloneOpt =
    opt:
    lib.pipe opt [
      (lib.replaceStrings [ "-" ] [ "_" ])
      lib.toUpper
      (lib.add "RCLONE_")
    ];

  toEnvVal = v: if lib.isBool v then lib.boolToString v else v;
  attrsToEnvs =
    attrs:
    lib.pipe attrs [
      (lib.mapAttrsToList (k: v: if v != null then "${k}=${toEnvVal v}" else [ ]))
      lib.flatten
    ];

  runtimeInputs = with pkgs; [
    coreutils
    findutils
    diffutils
    jq
    gnugrep
    which
  ];
in
{
  options.services.restic = {
    enable = lib.mkEnableOption "restic";

    backups = lib.mkOption {
      description = ''
        Periodic backups to create with Restic.
      '';
      type = lib.types.attrsOf (
        lib.types.submodule (
          { config, name, ... }:
          {
            options = {
              package = lib.mkPackageOption pkgs "restic" { };

              ssh-package = lib.mkPackageOption pkgs "openssh" { };

              passwordFile = lib.mkOption {
                type = lib.types.str;
                description = ''
                  A file containing the repository password.
                '';
                example = "/etc/nixos/restic-password";
              };

              environmentFile = lib.mkOption {
                type = with lib.types; nullOr str;
                default = null;
                description = ''
                  A file containing the credentials to access the repository, in the
                  format of an EnvironmentFile as described by {manpage}`systemd.exec(5)`.
                  See <https://restic.readthedocs.io/en/stable/030_preparing_a_new_repo.html>
                  for the specific credentials you will need for your backend.
                '';
              };

              rcloneOptions = lib.mkOption {
                type =
                  with lib.types;
                  attrsOf (oneOf [
                    str
                    bool
                  ]);
                default = { };
                apply = lib.mapAttrs' (opt: v: lib.nameValuePair (fmtRcloneOpt opt) v);
                description = ''
                  Options to pass to rclone to control its behavior. See
                  <https://rclone.org/docs/#options> for available options. When specifying
                  option names, strip the leading `--`. To set a flag such as
                  `--drive-use-trash`, which does not take a value, set the value to the
                  Boolean `true`.
                '';
                example = {
                  bwlimit = "10M";
                  drive-use-trash = true;
                };
              };

              inhibitsSleep = lib.mkOption {
                default = false;
                type = lib.types.bool;
                example = true;
                description = ''
                  Prevents the system from sleeping while backing up. This uses systemd-inhibit
                  to block system idling so you may need to enable polkitd with
                  {option}`security.polkit.enable`.
                '';
              };

              repository = lib.mkOption {
                type = with lib.types; nullOr str;
                default = null;
                description = ''
                  Repository to backup to. This should be in the form of a backend specification as
                  detailed here
                  <https://restic.readthedocs.io/en/stable/030_preparing_a_new_repo.html>.

                  If your using the rclone backend, you can configure your remotes with
                  {option}`programs.rclone.remotes` then use them in your backend specification.
                '';
                example = "sftp:backup@192.168.1.100:/backups/${name}";
              };

              repositoryFile = lib.mkOption {
                type = with lib.types; nullOr path;
                default = null;
                description = ''
                  Path to a file containing the repository location to backup to. This should be
                  in the same form as the {option}`repository` option.
                '';
              };

              paths = lib.mkOption {
                type = with lib.types; listOf str;
                default = [ ];
                description = ''
                  Paths to back up, alongside those defined by the {option}`dynamicFilesFrom`
                  option. If left empty and {option}`dynamicFilesFrom` is also not specified, no
                  backup command will be run. This can be used to create a prune-only job.
                '';
                example = [
                  "/var/lib/postgresql"
                  "/home/user/backup"
                ];
              };

              exclude = lib.mkOption {
                type = with lib.types; listOf str;
                default = [ ];
                description = ''
                  Patterns to exclude when backing up. See
                  <https://restic.readthedocs.io/en/stable/040_backup.html#excluding-files> for
                  details on syntax.
                '';
                example = [
                  "/var/cache"
                  "/home/*/.cache"
                  ".git"
                ];
              };

              timerConfig = lib.mkOption {
                type = lib.types.nullOr unitType;
                default = {
                  OnCalendar = "daily";
                  Persistent = true;
                };
                description = ''
                  When to run the backup. See {manpage}`systemd.timer(5)` for details. If null
                  no timer is created and the backup will only run when explicitly started.
                '';
                example = {
                  OnCalendar = "00:05";
                  RandomizedDelaySec = "5h";
                  Persistent = true;
                };
              };

              extraBackupArgs = lib.mkOption {
                type = with lib.types; listOf str;
                default = [ ];
                description = ''
                  Extra arguments passed to restic backup.
                '';
                example = [
                  "--cleanup-cache"
                  "--exclude-file=/etc/nixos/restic-ignore"
                ];
              };

              extraOptions = lib.mkOption {
                type = with lib.types; listOf str;
                default = [ ];
                description = ''
                  Extra extended options to be passed to the restic `-o` flag. See the restic
                  documentation for more details.
                '';
                example = [
                  "sftp.command='ssh backup@192.168.1.100 -i /home/user/.ssh/id_rsa -s sftp'"
                ];
              };

              initialize = lib.mkOption {
                type = lib.types.bool;
                default = false;
                description = ''
                  Create the repository if it does not already exist.
                '';
              };

              pruneOpts = lib.mkOption {
                type = with lib.types; listOf str;
                default = [ ];
                description = ''
                  A list of policy options for 'restic forget --prune', to automatically
                  prune old snapshots. See
                  <https://restic.readthedocs.io/en/latest/060_forget.html#removing-snapshots-according-to-a-policy>
                  for a full list of options.

                  Note: The 'forget' command is run *after* the 'backup' command, so keep
                  that in mind when constructing the --keep-\* options.
                '';
                example = [
                  "--keep-daily 7"
                  "--keep-weekly 5"
                  "--keep-monthly 12"
                  "--keep-yearly 75"
                ];
              };

              runCheck = lib.mkOption {
                type = lib.types.bool;
                default = lib.length config.checkOpts > 0 || lib.length config.pruneOpts > 0;
                defaultText = lib.literalExpression "lib.length config.checkOpts > 0 || lib.length config.pruneOpts > 0";
                description = "Whether to run 'restic check' with the provided `checkOpts` options.";
                example = true;
              };

              checkOpts = lib.mkOption {
                type = with lib.types; listOf str;
                default = [ ];
                description = ''
                  A list of options for 'restic check'.
                '';
                example = [ "--with-cache" ];
              };

              dynamicFilesFrom = lib.mkOption {
                type = with lib.types; nullOr str;
                default = null;
                description = ''
                  A script that produces a list of files to back up. The results of
                  this command, along with the paths specified via {option}`paths`,
                  are given to the '--files-from' option.
                '';
                example = "find /home/alice/git -type d -name .git";
              };

              backupPrepareCommand = lib.mkOption {
                type = with lib.types; nullOr str;
                default = null;
                description = ''
                  A script that must run before starting the backup process.
                '';
              };

              backupCleanupCommand = lib.mkOption {
                type = with lib.types; nullOr str;
                default = null;
                description = ''
                  A script that must run after finishing the backup process.
                '';
              };

              createWrapper = lib.mkOption {
                type = lib.types.bool;
                default = true;
                description = ''
                  Whether to generate and add a script to the system path, that has the
                  same environment variables set as the systemd service. This can be used
                  to e.g. mount snapshots or perform other opterations, without having to
                  manually specify most options.
                '';
              };

              progressFps = lib.mkOption {
                type = with lib.types; nullOr numbers.nonnegative;
                default = null;
                description = ''
                  Controls the frequency of progress reporting.
                '';
                example = 0.1;
              };
            };
          }
        )
      );
      default = { };
      example = {
        localbackup = {
          paths = [ "/home" ];
          exclude = [ "/home/*/.cache" ];
          repository = "/mnt/backup-hdd";
          passwordFile = "/etc/nixos/secrets/restic-password";
          initialize = true;
        };
        remotebackup = {
          paths = [ "/home" ];
          repository = "sftp:backup@host:/backups/home";
          passwordFile = "/etc/nixos/secrets/restic-password";
          extraOptions = [
            "sftp.command='ssh backup@host -i /etc/nixos/secrets/backup-private-key -s sftp'"
          ];
          timerConfig = {
            OnCalendar = "00:05";
            RandomizedDelaySec = "5h";
          };
        };
      };
    };
  };

  config = lib.mkIf cfg.enable {
    assertions = lib.mapAttrsToList (n: v: {
      assertion = lib.xor (v.repository == null) (v.repositoryFile == null);
      message = "services.restic.backups.${n}: exactly one of repository or repositoryFile should be set";
    }) cfg.backups;

    systemd.user.services = lib.mapAttrs' (
      name: backup:
      let
        doBackup = backup.dynamicFilesFrom != null || backup.paths != [ ];
        doPrune = backup.pruneOpts != [ ];
        doCheck = backup.runCheck;
        serviceName = "restic-backups-${name}";

        extraOptions = lib.concatMap (arg: [
          "-o"
          arg
        ]) backup.extraOptions;

        excludeFile = pkgs.writeText "exclude-patterns" (lib.concatLines backup.exclude);
        excludeFileFlag = "--exclude-file=${excludeFile}";

        filesFromTmpFile = "/run/user/$UID/${serviceName}/includes";
        filesFromFlag = "--files-from=${filesFromTmpFile}";

        inhibitCmd = lib.optionals backup.inhibitsSleep [
          "${pkgs.systemd}/bin/systemd-inhibit"
          "--mode='block'"
          "--who='restic'"
          "--what='idle'"
          "--why=${lib.escapeShellArg "Scheduled backup ${name}"}"
        ];

        mkResticCmd' =
          pre: args:
          lib.concatStringsSep " " (
            pre ++ lib.singleton (lib.getExe backup.package) ++ extraOptions ++ lib.flatten args
          );
        mkResticCmd = mkResticCmd' [ ];

        backupCmd =
          "${lib.getExe pkgs.bash} -c "
          + lib.escapeShellArg (
            mkResticCmd' inhibitCmd [
              "backup"
              backup.extraBackupArgs
              excludeFileFlag
              filesFromFlag
            ]
          );

        forgetCmd = mkResticCmd [
          "forget"
          "--prune"
          backup.pruneOpts
        ];
        checkCmd = mkResticCmd [
          "check"
          backup.checkOpts
        ];
        unlockCmd = mkResticCmd "unlock";
      in
      lib.nameValuePair serviceName {
        Unit = {
          Description = "Restic backup service";
          Wants = [ "network-online.target" ];
          After = [ "network-online.target" ];
        };

        Service = {
          Type = "oneshot";

          X-RestartIfChanged = true;
          RuntimeDirectory = serviceName;
          CacheDirectory = serviceName;
          CacheDirectoryMode = "0700";
          PrivateTmp = true;

          Environment = [
            "RESTIC_CACHE_DIR=%C"
            "PATH=${backup.ssh-package}/bin"
          ]
          ++ attrsToEnvs (
            {
              RESTIC_PROGRESS_FPS = backup.progressFps;
              RESTIC_PASSWORD_FILE = backup.passwordFile;
              RESTIC_REPOSITORY = backup.repository;
              RESTIC_REPOSITORY_FILE = backup.repositoryFile;
            }
            // backup.rcloneOptions
          );

          ExecStart =
            lib.optional doBackup backupCmd
            ++ lib.optionals doPrune [
              unlockCmd
              forgetCmd
            ]
            ++ lib.optional doCheck checkCmd;

          ExecStartPre = lib.getExe (
            pkgs.writeShellApplication {
              name = "${serviceName}-exec-start-pre";
              inherit runtimeInputs;
              text = ''
                set -x

                ${lib.optionalString (backup.backupPrepareCommand != null) ''
                  ${pkgs.writeScript "backupPrepareCommand" backup.backupPrepareCommand}
                ''}

                ${lib.optionalString (backup.initialize) ''
                  ${
                    mkResticCmd [
                      "cat"
                      "config"
                    ]
                  } 2>/dev/null || ${mkResticCmd "init"}
                ''}

                ${lib.optionalString (backup.paths != null && backup.paths != [ ]) ''
                  cat ${pkgs.writeText "staticPaths" (lib.concatLines backup.paths)} >> ${filesFromTmpFile}
                ''}

                ${lib.optionalString (backup.dynamicFilesFrom != null) ''
                  ${pkgs.writeScript "dynamicFilesFromScript" backup.dynamicFilesFrom} >> ${filesFromTmpFile}
                ''}
              '';
            }
          );

          ExecStopPost = lib.getExe (
            pkgs.writeShellApplication {
              name = "${serviceName}-exec-stop-post";
              inherit runtimeInputs;
              text = ''
                set -x

                ${lib.optionalString (backup.backupCleanupCommand != null) ''
                  ${pkgs.writeScript "backupCleanupCommand" backup.backupCleanupCommand}
                ''}
              '';
            }
          );
        }
        // lib.optionalAttrs (backup.environmentFile != null) {
          EnvironmentFile = backup.environmentFile;
        };
      }
    ) cfg.backups;

    systemd.user.timers = lib.mapAttrs' (
      name: backup:
      lib.nameValuePair "restic-backups-${name}" {
        Unit.Description = "Restic backup service";
        Install.WantedBy = [ "timers.target" ];

        Timer = backup.timerConfig;
      }
    ) (lib.filterAttrs (_: v: v.timerConfig != null) cfg.backups);

    home.packages = lib.mapAttrsToList (
      name: backup:
      let
        serviceName = "restic-backups-${name}";
        backupService = config.systemd.user.services.${serviceName};
        notPathVar = x: !(lib.hasPrefix "PATH" x);
        extraOptions = lib.concatMap (arg: [
          "-o"
          arg
        ]) backup.extraOptions;
        restic = lib.concatStringsSep " " (
          lib.flatten [
            (lib.getExe backup.package)
            extraOptions
          ]
        );
      in
      pkgs.writeShellApplication {
        name = "restic-${name}";
        excludeShellChecks = [
          # https://github.com/koalaman/shellcheck/issues/1986
          "SC2034"
          # Allow sourcing environmentFile
          "SC1091"
        ];
        bashOptions = [
          "errexit"
          "nounset"
          "allexport"
        ];
        text = ''
          ${lib.optionalString (backup.environmentFile != null) ''
            source ${backup.environmentFile}
          ''}

          # Set same environment variables as the systemd service
          ${lib.pipe backupService.Service.Environment [
            (lib.filter notPathVar)
            lib.concatLines
          ]}

          # Override this as %C will not work
          RESTIC_CACHE_DIR=$HOME/.cache/${serviceName}

          PATH=${
            lib.pipe backupService.Service.Environment [
              (lib.filter (lib.hasPrefix "PATH="))
              lib.head
              (lib.removePrefix "PATH=")
            ]
          }:$PATH

          exec ${restic} "$@"
        '';
      }
    ) (lib.filterAttrs (_: v: v.createWrapper) cfg.backups);
  };

  meta.maintainers = [ lib.maintainers.jess ];
}
