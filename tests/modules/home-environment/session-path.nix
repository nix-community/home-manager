{
  home.sessionPath = [
    ""
    "bar"
    "baz"
    "foo"
  ];

  test.asserts.warnings.expected = [
    ''
      `home.sessionPath` or `home.sessionSearchVariables` contains an empty
      entry, which Home Manager ignores. Write `.` to include the current
      directory. If the empty entry has tool-specific meaning, set the
      complete value through `home.sessionVariables` instead.
    ''
  ];

  nmt.script = ''
    hmSessVars=home-path/etc/profile.d/hm-session-vars.sh
    assertFileExists $hmSessVars

    # The generated file merges rather than concatenating, so assert the
    # resulting value instead of the text that produces it.
    (
      export PATH=/inherited/bin:baz
      unset __HM_SESS_VARS_SOURCED __HM_SESS_VARS_MERGED
      . "$TESTED/$hmSessVars"
      [ "$PATH" = "bar:baz:foo:/inherited/bin" ] \
        || { echo "PATH: $PATH"; exit 1; }
    ) || fail "home.sessionPath entries were not prepended"
  '';
}
