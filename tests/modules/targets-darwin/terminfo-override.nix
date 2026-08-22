{
  # A plain session variable no longer replaces Home Manager's handling: it
  # sets the base value, which the prepend and append sections then extend.
  # Use `targets.darwin.terminfo.enable = false` to opt out entirely.
  home.sessionVariables.TERMINFO_DIRS = "/custom/terminfo";

  nmt.script = ''
    sessionVarsFile=home-path/etc/profile.d/hm-session-vars.sh
    assertFileExists $sessionVarsFile
    assertFileContains $sessionVarsFile \
      'export TERMINFO_DIRS="/custom/terminfo"'
    assertFileContains $sessionVarsFile \
      '__hm_entry="/home/hm-user/.nix-profile/share/terminfo"'
    assertFileContains $sessionVarsFile \
      '__hm_entry="/usr/share/terminfo"'

    (
      # The plain assignment runs first, so the result does not depend on what
      # the environment happened to carry.
      export TERM="dumb" TERMINFO_DIRS="/inherited/terminfo"
      . "$TESTED/$sessionVarsFile"
      expected="/home/hm-user/.nix-profile/share/terminfo:/custom/terminfo:/usr/share/terminfo"
      [ "$TERMINFO_DIRS" = "$expected" ] \
        || { echo "after first source: $TERMINFO_DIRS"; exit 1; }
      . "$TESTED/$sessionVarsFile"
      [ "$TERMINFO_DIRS" = "$expected" ] \
        || { echo "after re-source: $TERMINFO_DIRS"; exit 1; }
    ) || fail "Darwin TERMINFO_DIRS override is not stable"
  '';
}
