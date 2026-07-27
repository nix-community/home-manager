{
  home.sessionVariables.TERMINFO_DIRS = null;

  nmt.script = ''
    sessionVarsFile=home-path/etc/profile.d/hm-session-vars.sh
    assertFileExists $sessionVarsFile
    assertFileNotRegex $sessionVarsFile 'export TERMINFO_DIRS='
    assertFileContains $sessionVarsFile 'export TERM="$TERM"'

    (
      export TERM="dumb" TERMINFO_DIRS="/inherited/terminfo"
      . "$TESTED/$sessionVarsFile"
      [ "$TERMINFO_DIRS" = "/inherited/terminfo" ] \
        || { echo "after first source: $TERMINFO_DIRS"; exit 1; }
      . "$TESTED/$sessionVarsFile"
      [ "$TERMINFO_DIRS" = "/inherited/terminfo" ] \
        || { echo "after re-source: $TERMINFO_DIRS"; exit 1; }
    ) || fail "Darwin TERMINFO_DIRS null opt-out is not stable"
  '';
}
