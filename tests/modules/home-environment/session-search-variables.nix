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
    (
      set -u
      unset TEST UNSET __HM_SESS_VARS_SOURCED __HM_SESS_VARS_MERGED
      . "$TESTED/$hmSessVars"
      [ "$TEST" = "bar:baz:foo" ] \
        || { echo "TEST after unset source: $TEST"; exit 1; }
      [ "$UNSET" = "configured" ] \
        || { echo "UNSET after unset source: $UNSET"; exit 1; }
      [ "$TRAILING" = "configured:inherited" ] \
        || { echo "TRAILING after source: $TRAILING"; exit 1; }
    ) || fail "search variables were not safe for unset targets"

    # First source in a process tree: configured entries take the precedence
    # they were configured with, so the inherited `baz` moves.
    (
      export TEST=/inherited:baz
      unset __HM_SESS_VARS_SOURCED __HM_SESS_VARS_MERGED
      . "$TESTED/$hmSessVars"
      [ "$TEST" = "bar:baz:foo:/inherited" ] \
        || { echo "TEST after first source: $TEST"; exit 1; }
    ) || fail "search variable entries were not prepended"

    # A later source must add only what is missing and leave positions alone.
    (
      export TEST=/inherited:baz
      export __HM_SESS_VARS_MERGED=1
      unset __HM_SESS_VARS_SOURCED
      . "$TESTED/$hmSessVars"
      [ "$TEST" = "bar:foo:/inherited:baz" ] \
        || { echo "TEST after later source: $TEST"; exit 1; }
    ) || fail "a later source reordered existing entries"
  '';
}
