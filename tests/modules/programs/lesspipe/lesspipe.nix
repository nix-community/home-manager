{
  programs.lesspipe.enable = true;

  test.stubs.lesspipe = { };

  nmt.script = ''
    assertFileContains home-path/etc/profile.d/hm-session-vars.sh \
      'export LESSOPEN="|@lesspipe@/bin/lesspipe.sh %s"'
  '';
}
