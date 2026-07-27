{ config, ... }:

{
  config = {
    # Regression test: the default must stay readable through the option
    # system, so other modules can refer to it.
    home.sessionVariables.TERMINFO_DIRS_COPY = config.home.sessionVariables.TERMINFO_DIRS;

    nmt.script = ''
      sessionVarsFile=home-path/etc/profile.d/hm-session-vars.sh
      assertFileExists $sessionVarsFile
      assertFileContains $sessionVarsFile \
        'export TERMINFO_DIRS="/home/hm-user/.nix-profile/share/terminfo:/usr/share/terminfo"'
      assertFileContains $sessionVarsFile \
        'export TERMINFO_DIRS_COPY="/home/hm-user/.nix-profile/share/terminfo:/usr/share/terminfo"'
      assertFileContains $sessionVarsFile \
        'export TERM="$TERM"'

      (
        # The default replaces an inherited value rather than extending it,
        # since a plain session variable must not reference itself.
        export TERM="dumb" TERMINFO_DIRS="/inherited/terminfo"
        . "$TESTED/$sessionVarsFile"
        expected="/home/hm-user/.nix-profile/share/terminfo:/usr/share/terminfo"
        [ "$TERMINFO_DIRS" = "$expected" ] \
          || { echo "after first source: $TERMINFO_DIRS"; exit 1; }
        . "$TESTED/$sessionVarsFile"
        [ "$TERMINFO_DIRS" = "$expected" ] \
          || { echo "after re-source: $TERMINFO_DIRS"; exit 1; }
      ) || fail "default Darwin TERMINFO_DIRS is not idempotent"
    '';
  };
}
