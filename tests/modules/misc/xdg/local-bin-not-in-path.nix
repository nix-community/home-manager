{
  xdg.localBinInPath = false;
  xdg.enable = true;

  nmt.script = ''
    assertFileExists home-path/etc/profile.d/hm-session-vars.sh
    assertFileNotRegex home-path/etc/profile.d/hm-session-vars.sh \
      '^export PATH="/home/hm-user/\.local/bin'
  '';
}
