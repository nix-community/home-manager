_:

{
  config = {
    home.sessionSearchVariables.TERMINFO_DIRS = [ "/my/terminfo" ];

    nmt.script = ''
      sessionVarsFile=home-path/etc/profile.d/hm-session-vars.sh
      assertFileExists $sessionVarsFile

      env -u __HM_SESS_VARS_SOURCED -u __HM_SESS_VARS_MERGED \
        TERM=dumb TERMINFO_DIRS=/inherited \
        "$BASH" -uc '
          . "$1"
          [ "$TERMINFO_DIRS" = "/home/hm-user/.nix-profile/share/terminfo:/my/terminfo:/inherited:/usr/share/terminfo" ] \
            || { echo "TERMINFO_DIRS: $TERMINFO_DIRS"; exit 1; }
          exit 0
        ' shell "$TESTED/$sessionVarsFile" \
        || fail "user TERMINFO_DIRS entries did not compose"
    '';
  };
}
