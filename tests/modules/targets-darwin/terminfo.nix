{
  config = {
    # User-provided fallbacks remain ahead of the system database, which must
    # stay last because it is the least-specific fallback.
    home.sessionSearchVariablesAppend.TERMINFO_DIRS = [ "/custom/fallback" ];

    nmt.script = ''
      sessionVarsFile=home-path/etc/profile.d/hm-session-vars.sh
      assertFileExists $sessionVarsFile
      # Home Manager's directory is prepended, /usr/share/terminfo appended.
      assertFileContains $sessionVarsFile \
        '__hm_entry="/home/hm-user/.nix-profile/share/terminfo"'
      assertFileContains $sessionVarsFile \
        '__hm_entry="/custom/fallback"'
      assertFileContains $sessionVarsFile \
        '__hm_entry="/usr/share/terminfo"'
      assertFileContains $sessionVarsFile \
        'export TERM="$TERM"'

      (
        # A value inherited from the environment keeps its position between
        # Home Manager's directory and the system fallback, matching the
        # pre-idempotent generator's result exactly.
        export TERM="dumb" TERMINFO_DIRS="/inherited/terminfo"
        . "$TESTED/$sessionVarsFile"
        expected="/home/hm-user/.nix-profile/share/terminfo:/inherited/terminfo:/custom/fallback:/usr/share/terminfo"
        [ "$TERMINFO_DIRS" = "$expected" ] \
          || { echo "after first source: $TERMINFO_DIRS"; exit 1; }
        . "$TESTED/$sessionVarsFile"
        [ "$TERMINFO_DIRS" = "$expected" ] \
          || { echo "after re-source: $TERMINFO_DIRS"; exit 1; }
      ) || fail "Darwin TERMINFO_DIRS does not preserve an inherited value"

      (
        # Unset is safe under `set -u` and yields just the two Home Manager
        # controlled entries.
        export TERM="dumb"
        unset TERMINFO_DIRS
        set -u
        . "$TESTED/$sessionVarsFile"
        expected="/home/hm-user/.nix-profile/share/terminfo:/custom/fallback:/usr/share/terminfo"
        [ "$TERMINFO_DIRS" = "$expected" ] \
          || { echo "from unset: $TERMINFO_DIRS"; exit 1; }
      ) || fail "Darwin TERMINFO_DIRS broken when unset"

      (
        # Existing entries keep their position and are not duplicated.
        export TERM="dumb" TERMINFO_DIRS="/inherited/terminfo:/usr/share/terminfo"
        . "$TESTED/$sessionVarsFile"
        expected="/home/hm-user/.nix-profile/share/terminfo:/inherited/terminfo:/usr/share/terminfo:/custom/fallback"
        [ "$TERMINFO_DIRS" = "$expected" ] \
          || { echo "with existing fallback: $TERMINFO_DIRS"; exit 1; }
      ) || fail "Darwin TERMINFO_DIRS duplicated the system fallback"
    '';
  };
}
