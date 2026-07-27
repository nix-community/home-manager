{
  home.sessionVariables.TERMINFO_DIRS = "/custom/terminfo";

  nmt.script = ''
    sessionVarsFile=home-path/etc/profile.d/hm-session-vars.sh
    assertFileExists $sessionVarsFile
    assertFileContains $sessionVarsFile \
      'export TERMINFO_DIRS="/custom/terminfo"'
    assertFileNotRegex $sessionVarsFile \
      '/home/hm-user/.nix-profile/share/terminfo'

    (
      export TERM="dumb" TERMINFO_DIRS="/inherited/terminfo"
      . "$TESTED/$sessionVarsFile"
      [ "$TERMINFO_DIRS" = "/custom/terminfo" ] \
        || { echo "after first source: $TERMINFO_DIRS"; exit 1; }
      . "$TESTED/$sessionVarsFile"
      [ "$TERMINFO_DIRS" = "/custom/terminfo" ] \
        || { echo "after re-source: $TERMINFO_DIRS"; exit 1; }
    ) || fail "Darwin TERMINFO_DIRS override is not stable"
  '';
}
