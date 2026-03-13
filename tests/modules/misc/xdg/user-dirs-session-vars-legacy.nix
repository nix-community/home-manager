{
  home.stateVersion = "25.11";

  xdg.userDirs.enable = true;

  nmt.script = ''
    assertFileContains home-path/etc/profile.d/hm-session-vars.sh \
      'export XDG_DESKTOP_DIR="/home/hm-user/Desktop"'
  '';
}
