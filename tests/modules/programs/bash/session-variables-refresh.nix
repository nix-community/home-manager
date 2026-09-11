_:

{
  programs.bash.enable = true;

  home.sessionVariables.GENERIC = "current";
  programs.bash.sessionVariables = {
    BASH_OWNED = "from-bash";
    # A value spanning lines is emitted verbatim inside double quotes, so
    # anything that reformats the export statement changes the value.
    BASH_MULTILINE = "first\nsecond";
    REPEATED = "$REPEATED:again";
  };
  home.sessionPath = [
    "/hm/bin"
    "/hm/extra"
  ];

  programs.bash.profileExtra = ''
    export FROM_PROFILE_EXTRA=login-only
    export BASH_OWNED=login-override
  '';
  programs.bash.bashrcExtra = ''
    export FROM_BASHRC_EXTRA=every-shell
  '';
  programs.bash.initExtra = ''
    export GENERIC=overridden-by-initExtra
  '';

  test.asserts.warnings.expected = [
    ''
      The following programs.bash.sessionVariables may change when applied again:

        REPEATED, defined in `${toString ./session-variables-refresh.nix}'

      Home Manager applies these values in each interactive non-login Bash
      shell, so self-referential values can change repeatedly.

      For search paths, use home.sessionPath,
      home.sessionSearchVariables, or home.sessionSearchVariablesAppend.
      Those options add only the entries that are missing. For other
      variables, assign a complete value without referring to its previous
      contents.

      This check is best-effort and detects only direct parameter references
      such as $NAME, ''${NAME...}, and ''${#NAME}.
    ''
  ];

  nmt.script = ''
    assertFileExists home-files/.bashrc
    assertFileExists home-files/.profile

    testHome=$TMPDIR/home
    mkdir -p "$testHome"
    cp "$TESTED/home-files/.bashrc" "$testHome/.bashrc"
    cp "$TESTED/home-files/.profile" "$testHome/.profile"

    # An interactive non-login shell refreshes generic and Bash-owned values,
    # and initExtra still wins because it runs after the refresh.
    env -u __HM_SESS_VARS_SOURCED -u __HM_SESS_VARS_MERGED \
      HOME="$testHome" TERM=dumb PATH=/usr/bin \
      GENERIC=stale BASH_OWNED=stale \
      "$BASH" --noprofile --norc -ic '
        . "$HOME/.bashrc"
        [ "$GENERIC" = overridden-by-initExtra ] \
          || { echo "GENERIC: $GENERIC"; exit 1; }
        [ "$BASH_OWNED" = from-bash ] \
          || { echo "BASH_OWNED: $BASH_OWNED"; exit 1; }
        [ "$FROM_BASHRC_EXTRA" = every-shell ] \
          || { echo "bashrcExtra did not run"; exit 1; }
        case ":$PATH:" in *:/hm/bin:*) ;; *) echo "sessionPath missing: $PATH"; exit 1 ;; esac
        exit 0
      ' \
      || fail "interactive non-login shell did not refresh"

    # Search paths stay stable, while plain Bash values are re-evaluated.
    env -u __HM_SESS_VARS_SOURCED -u __HM_SESS_VARS_MERGED \
      HOME="$testHome" TERM=dumb PATH=/usr/bin REPEATED=base \
      "$BASH" --noprofile --norc -ic '
        . "$HOME/.bashrc"
        first="$PATH"
        [ "$REPEATED" = base:again ] \
          || { echo "first REPEATED: $REPEATED"; exit 1; }
        . "$HOME/.bashrc"
        [ "$PATH" = "$first" ] || { echo "PATH grew: $PATH"; exit 1; }
        [ "$REPEATED" = base:again:again ] \
          || { echo "second REPEATED: $REPEATED"; exit 1; }
        exit 0
      ' \
      || fail "repeated .bashrc sourcing was not idempotent"

    # The headline case: a terminal spawned from a session that already
    # sourced an older generation. Both guards are inherited, a managed value
    # is stale, and PATH lost one configured entry while keeping the other in
    # a position something else chose.
    env __HM_SESS_VARS_SOURCED=1 __HM_SESS_VARS_MERGED=1 \
      HOME="$testHome" TERM=dumb PATH=/usr/bin:/hm/extra:/bin \
      BASH_OWNED=stale \
      "$BASH" --noprofile --norc -ic '
        . "$HOME/.bashrc"
        [ "$BASH_OWNED" = from-bash ] \
          || { echo "stale value survived: $BASH_OWNED"; exit 1; }
        case ":$PATH:" in
          *:/hm/bin:*) ;;
          *) echo "missing entry not added: $PATH"; exit 1 ;;
        esac
        # /hm/extra was already present, so a later merge must leave it where
        # it was instead of pulling it back to the configured position.
        [ "$PATH" = /hm/bin:/usr/bin:/hm/extra:/bin ] \
          || { echo "PATH repositioned: $PATH"; exit 1; }
        exit 0
      ' \
      || fail "stale session was not refreshed"

    # A multi-line value must survive the refresh unchanged: an interactive
    # non-login shell has to see exactly what a login shell sees.
    expected=$(printf 'first\nsecond')

    nonLogin=$(env -u __HM_SESS_VARS_SOURCED -u __HM_SESS_VARS_MERGED \
      HOME="$testHome" TERM=dumb PATH=/usr/bin \
      "$BASH" --noprofile --norc -ic '
        . "$HOME/.bashrc"
        printf "%s" "$BASH_MULTILINE"
      ') || fail "multi-line refresh shell failed"

    login=$(env -u __HM_SESS_VARS_SOURCED -u __HM_SESS_VARS_MERGED \
      HOME="$testHome" TERM=dumb PATH=/usr/bin \
      "$BASH" --noprofile --norc -lic '
        . "$HOME/.profile"
        printf "%s" "$BASH_MULTILINE"
      ') || fail "multi-line login shell failed"

    [ "$login" = "$expected" ] \
      || fail "login shell multi-line value: <$login>"
    [ "$nonLogin" = "$login" ] \
      || fail "refresh changed a multi-line value: <$nonLogin>"

    # A login shell must not run the refresh: .profile already did it, and
    # profileExtra runs after it there.
    env -u __HM_SESS_VARS_SOURCED -u __HM_SESS_VARS_MERGED \
      HOME="$testHome" TERM=dumb PATH=/usr/bin \
      "$BASH" --noprofile --norc -lic '
        . "$HOME/.profile"
        [ "$FROM_PROFILE_EXTRA" = login-only ] \
          || { echo "profileExtra did not run at login"; exit 1; }
        [ "$GENERIC" = current ] || { echo "GENERIC: $GENERIC"; exit 1; }
        exit 0
      ' \
      || fail "login shell path broken"

    # The distro layout: a .bash_profile that chains .bashrc. .bashrc runs in
    # a login shell there, so the refresh must stay out of the way and let
    # profileExtra keep the last word over a name Home Manager also manages.
    env -u __HM_SESS_VARS_SOURCED -u __HM_SESS_VARS_MERGED \
      HOME="$testHome" TERM=dumb PATH=/usr/bin \
      "$BASH" --noprofile --norc -lic '
        . "$HOME/.profile"
        . "$HOME/.bashrc"
        [ "$BASH_OWNED" = login-override ] \
          || { echo "refresh ran in a login shell: $BASH_OWNED"; exit 1; }
        [ "$FROM_BASHRC_EXTRA" = every-shell ] \
          || { echo "bashrcExtra did not run at login"; exit 1; }
        exit 0
      ' \
      || fail "login shell chaining .bashrc lost profileExtra"

    # Non-interactive shells must stay silent and untouched. bash reads
    # .bashrc for `ssh host cmd`, where any output breaks scp and rsync.
    out=$(env -u __HM_SESS_VARS_SOURCED -u __HM_SESS_VARS_MERGED \
      HOME="$testHome" TERM=dumb PATH=/usr/bin GENERIC=stale \
      "$BASH" --noprofile --norc -c '
        . "$HOME/.bashrc"
        printf "%s" "$GENERIC"
      ')
    [ "$out" = stale ] \
      || fail "non-interactive shell was modified or noisy: <$out>"
  '';
}
