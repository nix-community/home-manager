{
  programs.rclone.remotes = {
    alices-cool-remote.config = {
      type = "sftp";
      host = "backup-server";
      user = "alice";
      key_file = "/key/path/foo";
    };
  };
}
