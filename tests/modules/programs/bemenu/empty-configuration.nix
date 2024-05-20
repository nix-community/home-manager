{
  programs.bemenu = { enable = true; };

  test.stubs.bemenu = { };

  nmt.script = ''
    assertFileExists home-path/etc/profile.d/hm-session-vars.sh
    assertFileNotRegex home-path/etc/profile.d/hm-session-vars.sh \
      "export BEMENU_OPTS"
  '';
}
