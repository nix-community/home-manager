_: {
  programs.rclone = {
    enable = true;
    remotes.myremote.config.type = "local";
  };

  # make sure config service exists
  nmt.script = ''
    assertFileExists home-files/.config/systemd/user/rclone-config.service
  '';
}
