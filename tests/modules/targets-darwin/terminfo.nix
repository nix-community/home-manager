{ realPkgs, ... }:

{
  config = {
    nmt.script = ''
      sessionVarsFile=home-path/etc/profile.d/hm-session-vars.sh
      assertFileExists $sessionVarsFile
      assertFileContains $sessionVarsFile \
        'export TERM="$TERM"'

      for shellBin in \
        "$BASH" \
        ${realPkgs.dash}/bin/dash \
        "${realPkgs.zsh}/bin/zsh -f"; do

        # Home Manager's directory wins, the system path stays last, and an
        # inherited directory keeps its place between the two.
        env -u __HM_SESS_VARS_SOURCED -u __HM_SESS_VARS_MERGED \
          TERM=dumb TERMINFO_DIRS=/inherited/terminfo \
          $shellBin -uc '
            . "$1"
            [ "$TERMINFO_DIRS" = "/home/hm-user/.nix-profile/share/terminfo:/inherited/terminfo:/usr/share/terminfo" ] \
              || { echo "TERMINFO_DIRS: $TERMINFO_DIRS"; exit 1; }
            exit 0
          ' shell "$TESTED/$sessionVarsFile" \
          || fail "$shellBin: TERMINFO_DIRS did not compose"

        # Safe when TERMINFO_DIRS is unset, which is the usual macOS case.
        env -u __HM_SESS_VARS_SOURCED -u __HM_SESS_VARS_MERGED \
          TERM=dumb \
          $shellBin -uc '
            unset TERMINFO_DIRS
            . "$1"
            [ "$TERMINFO_DIRS" = "/home/hm-user/.nix-profile/share/terminfo:/usr/share/terminfo" ] \
              || { echo "TERMINFO_DIRS: $TERMINFO_DIRS"; exit 1; }
            exit 0
          ' shell "$TESTED/$sessionVarsFile" \
          || fail "$shellBin: TERMINFO_DIRS broken when unset"

        # No duplicate system fallback when it is already inherited.
        env -u __HM_SESS_VARS_SOURCED -u __HM_SESS_VARS_MERGED \
          TERM=dumb TERMINFO_DIRS=/usr/share/terminfo \
          $shellBin -uc '
            . "$1"
            [ "$TERMINFO_DIRS" = "/home/hm-user/.nix-profile/share/terminfo:/usr/share/terminfo" ] \
              || { echo "TERMINFO_DIRS: $TERMINFO_DIRS"; exit 1; }
            exit 0
          ' shell "$TESTED/$sessionVarsFile" \
          || fail "$shellBin: duplicated the system terminfo path"

        # Later merges preserve existing configured-entry positions.
        env -u __HM_SESS_VARS_SOURCED \
          __HM_SESS_VARS_MERGED=1 \
          TERM=dumb \
          TERMINFO_DIRS=/usr/share/terminfo:/inherited/terminfo:/home/hm-user/.nix-profile/share/terminfo \
          $shellBin -uc '
            . "$1"
            [ "$TERMINFO_DIRS" = "/usr/share/terminfo:/inherited/terminfo:/home/hm-user/.nix-profile/share/terminfo" ] \
              || { echo "TERMINFO_DIRS: $TERMINFO_DIRS"; exit 1; }
            exit 0
          ' shell "$TESTED/$sessionVarsFile" \
          || fail "$shellBin: later merge repositioned TERMINFO_DIRS entries"
      done
    '';
  };
}
