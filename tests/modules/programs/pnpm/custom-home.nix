{
  programs.pnpm = {
    enable = true;
    pnpmHome = "/home/hm-user/.pnpm";
  };

  nmt.script = ''
    hmSessVars=home-path/etc/profile.d/hm-session-vars.sh

    assertFileExists $hmSessVars
    assertFileContains $hmSessVars \
      'export PNPM_HOME="/home/hm-user/.pnpm"'
    (
      export PATH=/inherited/bin
      unset __HM_SESS_VARS_SOURCED __HM_SESS_VARS_MERGED
      . "$TESTED/$hmSessVars"
      [ "$PATH" = "/home/hm-user/.pnpm/bin:/inherited/bin" ] \
        || { echo "PATH: $PATH"; exit 1; }
    ) || fail "pnpm bin directory was not prepended to PATH"
  '';
}
