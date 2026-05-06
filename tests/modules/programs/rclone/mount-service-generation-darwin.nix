_: {
  programs.rclone = {
    enable = true;
    remotes.sftp-remote = {
      config = {
        type = "sftp";
        host = "backup-server.example.com";
        user = "alice";
        key_file = "/Users/alice/.ssh/id_ed25519";
      };
      mounts = {
        "documents/work" = {
          enable = true;
          mountPoint = "/Users/alice/mounts/work-docs";
          logLevel = "INFO";
          options = {
            dir-cache-time = "5000h";
            poll-interval = "10s";
            umask = "002";
          };
        };
        "disabled-mount" = {
          enable = false;
          mountPoint = "/Users/alice/mounts/disabled";
        };
      };
    };
  };

  nmt.script = ''
    plist="LaunchAgents/org.nix-community.home.rclone-mount:documents.work@sftp-remote.plist"
    assertFileExists "$plist"

    # rclone command line is wrapped by the launchd module in
    # `/bin/sh -c "/bin/wait4path /nix/store && exec <args>"`,
    # then by our rclone-sidecar-wrapper. Check for the meaningful
    # substrings rather than the full quoted form.
    assertFileContains "$plist" "rclone-sidecar-wrapper"
    assertFileContains "$plist" "/bin/rclone"
    assertFileContains "$plist" "mount"
    assertFileContains "$plist" "&apos;--cache-dir=/home/hm-user/.cache/rclone&apos;"
    assertFileContains "$plist" "&apos;--vfs-cache-mode=full&apos;"
    assertFileContains "$plist" "&apos;--dir-cache-time=5000h&apos;"
    assertFileContains "$plist" "&apos;--poll-interval=10s&apos;"
    assertFileContains "$plist" "&apos;--umask=002&apos;"
    assertFileContains "$plist" "sftp-remote:documents/work"
    assertFileContains "$plist" "/Users/alice/mounts/work-docs"

    # Lifecycle keys
    assertFileContains "$plist" "<key>RunAtLoad</key>"
    assertFileContains "$plist" "<key>KeepAlive</key>"
    assertFileContains "$plist" "<key>Crashed</key>"

    # Logs route under ~/Library/Logs/rclone/
    assertFileContains "$plist" "Library/Logs/rclone"

    # Log level surfaces as an environment variable
    assertFileContains "$plist" "RCLONE_LOG_LEVEL"
    assertFileContains "$plist" "INFO"

    # Disabled mount produces no plist
    assertPathNotExists "LaunchAgents/org.nix-community.home.rclone-mount:disabled-mount@sftp-remote.plist"
  '';
}
