{ pkgs, ... }:
let
  passwordFile = "/home/alice/password";
  paths = [ "/home/alice/files" ];
  exclude = [ "*exclude*" ];
in
{
  home.username = "alice";
  home.homeDirectory = "/home/alice";

  home.stateVersion = "24.05"; # Please read the comment before changing.

  # Let Home Manager install and manage itself.
  programs.home-manager.enable = true;
  systemd.user.startServices = false;

  programs.rclone = {
    enable = true;
    remotes = {
      alices-computer.config = {
        type = "local";
        one_file_system = true;
      };
    };
  };

  services.restic = {
    enable = true;
    backups = {
      init = {
        inherit passwordFile paths exclude;
        initialize = true;
        repository = "/home/alice/repos/backup";
      };

      noinit = {
        inherit passwordFile paths exclude;
        initialize = false;
        repository = "/home/alice/repos/noinit";
      };

      basic = {
        inherit passwordFile paths exclude;
        initialize = true;
        repository = "/home/alice/repos/basic";
      };

      repo-file = {
        inherit passwordFile paths exclude;
        initialize = true;
        repositoryFile = pkgs.writeText "repositoryFile" "/home/alice/repos/repo-file";
      };

      rclone = {
        inherit passwordFile paths exclude;
        initialize = true;
        repository = "rclone:alices-computer:/home/alice/repos/rclone";
      };

      dynamic-paths = {
        inherit passwordFile paths exclude;
        initialize = true;
        repository = "/home/alice/repos/dynamic-paths";
        dynamicFilesFrom = ''
          find /home/alice/dyn-files -type f ! -name "*secret*"
        '';
      };

      inhibits-sleep = {
        inherit passwordFile paths exclude;
        inhibitsSleep = true;
        initialize = true;
        repository = "/home/alice/repos/inhibits-sleep";
      };

      pre-post-jobs = {
        inherit passwordFile paths exclude;
        initialize = true;
        repository = "/home/alice/repos/pre-post-jobs";
        backupPrepareCommand = ''
          echo "Preparing Backup..."
          echo "Notifying Alice..."
          echo "Ready!"
        '';
        backupCleanupCommand = ''
          echo "Finishing Backup..."
          echo "Mailing alice the results..."
          echo "Done."
        '';
      };

      prune-me = {
        inherit passwordFile paths exclude;
        initialize = true;
        repository = "/home/alice/repos/prune-me";
      };

      prune-only = {
        inherit passwordFile;
        repository = "/home/alice/repos/prune-me";
        pruneOpts = [
          "--keep-yearly 4"
          "--keep-monthly 3"
          "--keep-weekly 2"
          "--keep-daily 2"
          "--keep-hourly 3"
        ];
      };

      prune-opts = {
        inherit passwordFile paths exclude;
        initialize = true;
        repository = "/home/alice/repos/prune-opts";
        pruneOpts = [
          "--keep-yearly 4"
          "--keep-monthly 3"
          "--keep-weekly 2"
          "--keep-daily 2"
          "--keep-hourly 3"
        ];
      };

      env-file = {
        inherit passwordFile paths exclude;
        initialize = true;
        repository = "/home/alice/repos/env-file";
        environmentFile = "${pkgs.writeText "environmentFile" ''
          SECRET=1234
          TOKEN=123456789ABcdEF
        ''}";
      };
    };
  };
}
