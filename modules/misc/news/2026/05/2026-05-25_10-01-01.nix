{
  time = "2026-05-25T10:01:01+00:00";
  condition = true;
  message = ''
    The source-guard in `hm-session-vars.sh` now keys off a hash of the
    variable definitions rather than a constant. This means that after
    `home-manager switch` changes `home.sessionVariables`, newly started
    shells pick up the updated values instead of skipping the file because
    a parent session already sourced an older generation. Previously the
    new values only took effect after a full re-login.

    Shells started from the same generation still source the file only once,
    so the de-duplication behaviour is unchanged. Already-running shells are
    not affected; they still need to be restarted to see new values.
  '';
}
