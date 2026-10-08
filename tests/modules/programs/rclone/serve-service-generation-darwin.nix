_: {
  programs.rclone = {
    enable = true;
    remotes = {
      sftp-remote = {
        config = {
          type = "sftp";
          host = "backup-server.example.com";
          user = "alice";
          key_file = "/Users/alice/.ssh/id_ed25519";
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
    # http serve
    plist="LaunchAgents/org.nix-community.home.rclone-serve:documents.work@sftp-remote.plist"
    assertFileExists "$plist"
    assertFileContains "$plist" "rclone-sidecar-wrapper"
    assertFileContains "$plist" "/bin/rclone"
    assertFileContains "$plist" "serve"
    assertFileContains "$plist" "http"
    assertFileContains "$plist" "&apos;--addr=127.0.0.1:8080&apos;"
    assertFileContains "$plist" "&apos;--cache-dir=/home/hm-user/.cache/rclone&apos;"
    assertFileContains "$plist" "&apos;--dir-cache-time=5000h&apos;"
    assertFileContains "$plist" "sftp-remote:documents/work"
    assertFileContains "$plist" "RCLONE_LOG_LEVEL"
    assertFileContains "$plist" "ERROR"

    # ftp serve
    plist2="LaunchAgents/org.nix-community.home.rclone-serve:.games@sftp-remote.plist"
    assertFileExists "$plist2"
    assertFileContains "$plist2" "ftp"
    assertFileContains "$plist2" "sftp-remote:/games"

    # Disabled serve produces no plist
    assertPathNotExists "LaunchAgents/org.nix-community.home.rclone-serve:disabled-serve@sftp-remote.plist"
  '';
}
