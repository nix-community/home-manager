{ ... }:

{
  imports = [
    ({ ... }: { config.home.sessionSearchVariables.TEST = [ "foo" ]; })
    ({ ... }: { config.home.sessionSearchVariables.TEST = [ "bar" "baz" ]; })
  ];

  nmt.script = ''
    hmSessVars=home-path/etc/profile.d/hm-session-vars.sh
    assertFileExists $hmSessVars
    assertFileContains $hmSessVars \
      'export TEST="bar:baz:foo''${TEST:+:}$TEST"'
  '';
}
