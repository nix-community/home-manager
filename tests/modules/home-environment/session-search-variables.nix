{
  home.sessionVariables.TRAILING = "inherited";

  home.sessionSearchVariables.TEST = [
    "bar"
    "baz"
    "foo"
  ];
  home.sessionSearchVariables.UNSET = [ "configured" ];
  home.sessionSearchVariables.TRAILING = [ "configured" ];

  nmt.script = ''
    hmSessVars=home-path/etc/profile.d/hm-session-vars.sh
    assertFileExists $hmSessVars
    testExport=$(grep '^export TEST=' "$TESTED/$hmSessVars")
    trailingExports=$(grep '^export TRAILING=' "$TESTED/$hmSessVars")
    unsetExport=$(grep '^export UNSET=' "$TESTED/$hmSessVars")
    (
      set -u
      unset TEST UNSET
      eval "$testExport"
      eval "$unsetExport"
      [ "$TEST" = "bar:baz:foo" ] \
        || { echo "TEST after unset source: $TEST"; exit 1; }
      [ "$UNSET" = "configured" ] \
        || { echo "UNSET after unset source: $UNSET"; exit 1; }
    ) || fail "search variables were not safe for unset targets"

    (
      set -u
      TEST=/inherited
      eval "$testExport"
      eval "$trailingExports"
      [ "$TEST" = "bar:baz:foo:/inherited" ] \
        || { echo "TEST after inherited source: $TEST"; exit 1; }
      [ "$TRAILING" = "configured:inherited" ] \
        || { echo "TRAILING after source: $TRAILING"; exit 1; }
    ) || fail "inherited search variable was not preserved"
  '';
}
