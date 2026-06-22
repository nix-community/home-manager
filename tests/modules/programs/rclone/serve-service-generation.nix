_: {
  programs.rclone = {
    enable = true;
    remotes = {
      sftp-remote = {
        config = {
          type = "sftp";
          host = "backup-server.example.com";
          user = "alice";
          key_file = "/home/alice/.ssh/id_ed25519";
        };
        serve = {
          "documents/work" = {
            enable = true;
            protocol = "http";
            logLevel = "ERROR";
            options = {
              addr = "127.0.0.1:8080";
              dir-cache-time = "5000h";
            };
          };
          "/games" = {
            enable = true;
            protocol = "ftp";
          };
          "disabled-serve" = {
            enable = false;
            protocol = "ftp";
          };
        };
      };
    };
  };

  nmt.script = ''
    # test work documents serve
    service="home-files/.config/systemd/user/rclone-serve:documents.work@sftp-remote.service"
    assertFileExists "$service"
    assertFileContains "$service" "rclone serve http '--addr=127.0.0.1:8080' '--cache-dir=%C/rclone' '--dir-cache-time=5000h' '--vfs-cache-mode=full' sftp-remote:documents/work"
    assertFileContains "$service" "RCLONE_LOG_LEVEL=ERROR"
    assertFileContains "$service" "Rclone protocol serving for sftp-remote:documents/work"
    assertFileContains "$service" "Type=notify"

    # ftp protocol should not have Type=notify
    service2="home-files/.config/systemd/user/rclone-serve:.games@sftp-remote.service"
    assertFileExists "$service2"
    assertFileContains "$service2" "rclone serve ftp '--cache-dir=%C/rclone' '--vfs-cache-mode=full' sftp-remote:/games"
    assertFileContains "$service2" "Type=simple"

    # make sure disabled serve is not created
    assertPathNotExists "home-files/.config/systemd/user/rclone-serve:disabled-serve@sftp-remote.service"
  '';
}
