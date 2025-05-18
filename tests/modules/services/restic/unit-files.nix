{ pkgs, lib, ... }:
let
  backups = import ./backup-configs.nix { inherit pkgs; };
in
{
  services.restic = {
    enable = true;
    inherit backups;
  };

  nmt.script = ''
    backups=(
      ${lib.concatLines (lib.attrNames backups)}
    )

    serviceFiles=./home-files/.config/systemd/user
    defaultPruneOpts=("forget" "prune" "keep-daily" "2" "keep-weekly" "1" "keep-monthly" "1" "keep-yearly" "99")
    inhibitString=("systemd-inhibit" "mode" "block" "who" "restic" "what" "sleep" "why" "Scheduled backup inhibit-sleep")
    sftpStrings=("sftp.command=" "ssh" "backup@host" "/etc/nixos/secrets/backup-private-key" "sftp")

    # General prelim tests
    for backup in ''${backups[@]};
    do
      serviceFile=$serviceFiles/restic-backups-"$backup".service

      # these two are the only ones without pruneOpts
      if [ "$backup" != "local-backup" ] && [ "$backup" != "remote-backup" ]; then
        assertFileRegex $serviceFile "ExecStart=.*unlock"
        assertFileRegex $serviceFile "ExecStart=.*forget.*--prune"
        assertFileRegex $serviceFile "ExecStart=.*check"
      fi

      if [ "$backup" != "prune" ]; then
        assertFileRegex $serviceFile "ExecStart=.*--exclude-file"
        assertFileRegex $serviceFile "ExecStart=.*--files-from"
      fi

      assertFileExists $serviceFile
      assertFileRegex $serviceFile "CacheDirectory=restic-backups-$backup"
      assertFileRegex $serviceFile "Environment=.*PATH=.*openssh.*/bin"
      assertFileRegex $serviceFile "ExecStartPre"
      assertFileRegex $serviceFile "ExecStart=.*restic"
      assertFileRegex $serviceFile "ExecStopPost"
      assertFileRegex $serviceFile "Description=Restic backup service"
    done

    backup=local-backup
    serviceFile=$serviceFiles/restic-backups-"$backup".service
    assertFileRegex $serviceFile "Environment=RESTIC_REPOSITORY=/mnt/backup-hdd"
    assertFileRegex $serviceFile "Environment=RESTIC_PASSWORD_FILE"

    backup=remote-backup
    serviceFile=$serviceFiles/restic-backups-"$backup".service
    assertFileRegex $serviceFile "Environment=RESTIC_REPOSITORY=sftp:backup@host:/backups/home"
    assertFileRegex $serviceFile "Environment=RESTIC_PASSWORD_FILE"
    assertFileRegex $serviceFile "ExecStart=.*"
    for part in ''${sftpStrings[@]}; do
      assertFileRegex $serviceFile "ExecStart=.*$part"
    done

    backup=no-timer
    serviceFile=$serviceFiles/restic-backups-"$backup".service
    assertFileRegex $serviceFile "Environment=RESTIC_REPOSITORY=/root/restic-backup"
    assertFileRegex $serviceFile "Environment=RESTIC_PASSWORD_FILE"
    assertFileRegex $serviceFile "ExecStart=.*$defaultPruneOpts"
    for part in ''${defaultPruneOpts[@]}; do
      assertFileRegex $serviceFile "ExecStart=.*$part"
    done
    # TODO: assertFileNotExists
    timerUnit=$serviceFiles/timers.target.wants/restic-backups-"$backup".timer
    if [ -f $(_abs $timerUnit) ]; then
      fail "restic backup config: \"$backup\" made a timer unit: $timerUnit when \`timerConfig = null\`"
    fi

    backup=repo-file
    serviceFile=$serviceFiles/restic-backups-"$backup".service
    assertFileRegex $serviceFile "Environment=RESTIC_REPOSITORY_FILE=.*repositoryFile"
    assertFileRegex $serviceFile "Environment=RESTIC_PASSWORD_FILE"
    assertFileRegex $serviceFile "ExecStart=.*$defaultPruneOpts"
    for part in ''${defaultPruneOpts[@]}; do
      assertFileRegex $serviceFile "ExecStart=.*$part"
    done

    backup=inhibit-sleep
    serviceFile=$serviceFiles/restic-backups-"$backup".service
    assertFileRegex $serviceFile "Environment=RESTIC_REPOSITORY=/root/restic-backup"
    assertFileRegex $serviceFile "Environment=RESTIC_PASSWORD_FILE"
    assertFileRegex $serviceFile "ExecStart=.*$defaultPruneOpts"
    for part in ''${defaultPruneOpts[@]}; do
      assertFileRegex $serviceFile "ExecStart=.*$part"
    done
    for part in ''${inhibitStrings[@]}; do
      assertFileRegex $serviceFile "ExecStart=.*$part"
    done

    backup=noinit
    serviceFile=$serviceFiles/restic-backups-"$backup".service
    assertFileRegex $serviceFile "Environment=RESTIC_REPOSITORY=/root/restic-backup"
    assertFileRegex $serviceFile "Environment=RESTIC_PASSWORD_FILE"
    assertFileRegex $serviceFile "ExecStart=.*$defaultPruneOpts"
    for part in ''${defaultPruneOpts[@]}; do
      assertFileRegex $serviceFile "ExecStart=.*$part"
    done

    backup=rclone
    serviceFile=$serviceFiles/restic-backups-"$backup".service
    assertFileRegex $serviceFile "Environment=RESTIC_REPOSITORY=rclone:local:/root/restic-rclone-backup"
    assertFileRegex $serviceFile "Environment=RESTIC_PASSWORD_FILE"
    assertFileRegex $serviceFile "ExecStart=.*$defaultPruneOpts"
    for part in ''${defaultPruneOpts[@]}; do
      assertFileRegex $serviceFile "ExecStart=.*$part"
    done

    backup=prune
    serviceFile=$serviceFiles/restic-backups-"$backup".service
    assertFileRegex $serviceFile "Environment=RESTIC_REPOSITORY=/root/restic-backup"
    assertFileRegex $serviceFile "Environment=RESTIC_PASSWORD_FILE"
    assertFileRegex $serviceFile "ExecStart=.*--prune --keep-last 1"

    backup=custom-package
    serviceFile=$serviceFiles/restic-backups-"$backup".service
    assertFileRegex $serviceFile "Environment=RESTIC_REPOSITORY=some-fake-repository"
    assertFileRegex $serviceFile "Environment=RESTIC_PASSWORD_FILE"
    assertFileRegex $serviceFile "ExecStart=.*forget --prune --keep-last 1"
    assertFileRegex $serviceFile "ExecStart=.*my-cool-restic"
    assertFileRegex $serviceFile "ExecStart=.*check --some-check-option"
  '';
}
