{
  home.sessionSearchVariables.TEST = [
    "bar"
    "baz"
    "foo"
  ];

  nmt.script = ''
    hmSessVars=home-path/etc/profile.d/hm-session-vars.sh
    assertFileExists $hmSessVars
    assertFileContains $hmSessVars \
      'export TEST="bar:baz:foo''${TEST:+:}$TEST"'
  '';
}
