{
  xdg.enable = true;
  xdg.localBinInPath = true;

  nmt.script = ''
    assertFileExists home-path/etc/profile.d/hm-session-vars.sh
    (
      export PATH=/inherited
      . "$TESTED/home-path/etc/profile.d/hm-session-vars.sh"
      [ "$PATH" = "/home/hm-user/.local/bin:/inherited" ]
    ) || fail "local bin directory was not prepended"
  '';
}
