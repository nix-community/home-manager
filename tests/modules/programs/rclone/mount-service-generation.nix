_: {
  programs.rclone = {
    enable = true;
    remotes.sftp-remote = {
      config = {
        type = "sftp";
        host = "backup-server.example.com";
        user = "alice";
        key_file = "/home/alice/.ssh/id_ed25519";
      };
      mounts = {
        "documents/work" = {
          enable = true;
          mountPoint = "/home/alice/mounts/work-docs";
          logLevel = "INFO";
          options = {
            dir-cache-time = "5000h";
            poll-interval = "10s";
            umask = "002";
          };
        };
        "disabled-mount" = {
          enable = false;
          mountPoint = "/home/alice/mounts/disabled";
        };
      };
    };
  };

  nmt.script = ''
    # test work documents mount
    service="home-files/.config/systemd/user/rclone-mount:documents.work@sftp-remote.service"
    assertFileExists "$service"
    assertFileContains "$service" "rclone mount '--cache-dir=%C/rclone' '--dir-cache-time=5000h' '--poll-interval=10s' '--umask=002' '--vfs-cache-mode=full' sftp-remote:documents/work /home/alice/mounts/work-docs"
    assertFileContains "$service" "mkdir -p /home/alice/mounts/work-docs"
    assertFileContains "$service" "RCLONE_LOG_LEVEL=INFO"
    assertFileContains "$service" "PATH=/run/wrappers/bin"
    assertFileContains "$service" "Rclone FUSE daemon for sftp-remote:documents/work"
    assertFileContains "$service" "Type=notify"

    # make sure disabled mount isn't created
    assertPathNotExists "home-files/.config/systemd/user/rclone-mount:disabled-mount@sftp-remote.service"
  '';
}
