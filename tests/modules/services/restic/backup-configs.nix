{ pkgs, ... }:
let
  repository = "/root/restic-backup";
  passwordFile = "/path/to/password";
  paths = [ "/etc" ];
  exclude = [
    "/etc/*.cache"
    "/opt/excluded_file_*"
  ];
  pruneOpts = [
    "--keep-daily 2"
    "--keep-weekly 1"
    "--keep-monthly 1"
    "--keep-yearly 99"
  ];
in
{
  local-backup = {
    repository = "/mnt/backup-hdd";
    inherit passwordFile paths exclude;
    initialize = true;
  };

  remote-backup = {
    repository = "sftp:backup@host:/backups/home";
    inherit passwordFile paths;
    extraOptions = [
      "sftp.command='ssh backup@host -i /etc/nixos/secrets/backup-private-key -s sftp'"
    ];
    timerConfig = {
      OnCalendar = "00:05";
      RandomizedDelaySec = "5h";
    };
  };

  no-timer = {
    inherit
      passwordFile
      paths
      exclude
      pruneOpts
      repository
      ;
    backupPrepareCommand = "dummy-prepare";
    backupCleanupCommand = "dummy-cleanup";
    initialize = true;
    timerConfig = null;
  };

  repo-file = {
    inherit
      passwordFile
      exclude
      pruneOpts
      paths
      ;
    initialize = true;
    repositoryFile = pkgs.writeText "repositoryFile" repository;
    dynamicFilesFrom = "find alices files";
  };

  inhibit-sleep = {
    inherit
      passwordFile
      paths
      exclude
      pruneOpts
      repository
      ;
    initialize = true;
    inhibitsSleep = true;
  };

  noinit = {
    inherit
      passwordFile
      exclude
      pruneOpts
      paths
      repository
      ;
    initialize = false;
  };

  rclone = {
    inherit
      passwordFile
      paths
      exclude
      pruneOpts
      ;
    initialize = true;
    repository = "rclone:local:/root/restic-rclone-backup";
  };

  prune = {
    inherit passwordFile repository;
    pruneOpts = [ "--keep-last 1" ];
  };

  custom-package = {
    inherit passwordFile paths;
    repository = "some-fake-repository";
    package = pkgs.writeShellScriptBin "my-cool-restic" ''
      echo "$@" >> /root/fake-restic.log;
    '';
    pruneOpts = [ "--keep-last 1" ];
    checkOpts = [ "--some-check-option" ];
  };
}
