{
  home.stateVersion = "26.05";

  xdg.userDirs.enable = true;

  nmt.script = ''
    assertFileNotRegex home-path/etc/profile.d/hm-session-vars.sh \
      '^export XDG_DESKTOP_DIR='
  '';
}
