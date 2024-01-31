{
  programs.bemenu = { enable = true; };

  nmt.script = ''
    assertFileExists home-path/etc/profile.d/hm-session-vars.sh
    assertFileNotRegex home-path/etc/profile.d/hm-session-vars.sh \
      "export BEMENU_OPTS"
  '';
}
