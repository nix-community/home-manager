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
          mountType = "nfsmount";
          mountPoint = "/Users/alice/mounts/work-docs";
          options = {
            dir-cache-time = "5000h";
          };
        };
        "documents/override" = {
          enable = true;
          mountType = "nfsmount";
          mountPoint = "/Users/alice/mounts/override";
          options = {
            nfs-cache-type = "memory";
          };
        };
      };
    };
  };

  nmt.script = ''
    plist="LaunchAgents/org.nix-community.home.rclone-nfsmount:documents.work@sftp-remote.plist"
    assertFileExists "$plist"

    # The agent must invoke `rclone nfsmount`, not the FUSE `mount` command.
    # (The rclone command line is wrapped by the launchd module in
    # `/bin/sh -c "/bin/wait4path /nix/store && exec <args>"`, so check
    # for the meaningful substring rather than a standalone plist string.)
    assertFileContains "$plist" "/bin/rclone nfsmount"

    # nfsmount defaults nfs-cache-type to disk so NFS file handles survive
    # rclone restarts; the shared mount/serve defaults still apply.
    assertFileContains "$plist" "&apos;--nfs-cache-type=disk&apos;"
    assertFileContains "$plist" "&apos;--vfs-cache-mode=full&apos;"
    assertFileContains "$plist" "&apos;--dir-cache-time=5000h&apos;"
    assertFileContains "$plist" "sftp-remote:documents/work"
    assertFileContains "$plist" "/Users/alice/mounts/work-docs"

    # Mount sidecars pre-create the mount point via the wrapper's --mkdir flag.
    assertFileContains "$plist" "rclone-sidecar-wrapper --mkdir"

    # A user-supplied nfs-cache-type overrides the disk default.
    override="LaunchAgents/org.nix-community.home.rclone-nfsmount:documents.override@sftp-remote.plist"
    assertFileExists "$override"
    assertFileContains "$override" "&apos;--nfs-cache-type=memory&apos;"
    assertFileNotRegex "$override" "nfs-cache-type=disk"
  '';
}
