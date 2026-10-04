{
  xdg.enable = true;
  xdg.localBinInPath = true;

  nmt.script = ''
    hmSessVars=home-path/etc/profile.d/hm-session-vars.sh
    assertFileExists $hmSessVars
    (
      export PATH=/inherited/bin
      unset __HM_SESS_VARS_SOURCED __HM_SESS_VARS_MERGED
      . "$TESTED/$hmSessVars"
      [ "$PATH" = "/home/hm-user/.local/bin:/inherited/bin" ] \
        || { echo "PATH: $PATH"; exit 1; }
    ) || fail "xdg.localBinInPath did not prepend the local bin directory"
  '';
}
