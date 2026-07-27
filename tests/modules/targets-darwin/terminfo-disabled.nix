{
  targets.darwin.terminfo.enable = false;

  # With Home Manager's handling disabled the user owns the variable outright.
  home.sessionVariables.TERMINFO_DIRS = "/custom/terminfo";

  nmt.script = ''
    sessionVarsFile=home-path/etc/profile.d/hm-session-vars.sh
    assertFileExists $sessionVarsFile
    assertFileContains $sessionVarsFile \
      'export TERMINFO_DIRS="/custom/terminfo"'
    assertFileNotRegex $sessionVarsFile '/nix-profile/share/terminfo'
    assertFileNotRegex $sessionVarsFile '/usr/share/terminfo'
    assertFileNotRegex $sessionVarsFile 'export TERM="\$TERM"'

    (
      export TERM="dumb" TERMINFO_DIRS="/inherited/terminfo"
      . "$TESTED/$sessionVarsFile"
      [ "$TERMINFO_DIRS" = "/custom/terminfo" ] \
        || { echo "after first source: $TERMINFO_DIRS"; exit 1; }
      . "$TESTED/$sessionVarsFile"
      [ "$TERMINFO_DIRS" = "/custom/terminfo" ] \
        || { echo "after re-source: $TERMINFO_DIRS"; exit 1; }
    ) || fail "disabled Darwin terminfo did not leave TERMINFO_DIRS alone"
  '';
}
