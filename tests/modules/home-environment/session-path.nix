{
  home.sessionPath = [
    "bar"
    "baz"
    "foo"
  ];

  nmt.script = ''
    hmSessVars=home-path/etc/profile.d/hm-session-vars.sh
    assertFileExists $hmSessVars
    assertFileContains $hmSessVars \
      '__hm_entry="bar"'
    assertFileContains $hmSessVars \
      '__hm_entry="baz"'
    assertFileContains $hmSessVars \
      '__hm_entry="foo"'
    assertFileContains $hmSessVars \
      '__hm_cur="''${PATH-}"'
    assertFileContains $hmSessVars \
      '  __hm_cur="$__hm_add''${__hm_cur:+:}$__hm_cur"'
    assertFileContains $hmSessVars \
      'export PATH="$__hm_cur"'
    # Each value must be prepended, not appended. Checked inside that
    # variable's own merge block: on Darwin the terminfo fallback adds a
    # genuine append block elsewhere in the same file.
    grep -B 3 -F 'export PATH="$__hm_cur"' "$TESTED/$hmSessVars" \
      | grep -qF '__hm_cur="$__hm_add' \
      || fail 'PATH must be prepended, not appended'

    # Runtime semantics: add-if-missing, idempotent re-source, no reorder.
    (
      # The Darwin extra section references TERM and TERMINFO_DIRS, which
      # are unset in the sandbox and would trip the test shell's `set -u`.
      export TERM="dumb" TERMINFO_DIRS=""
      export PATH="baz:/existing"
      . "$TESTED/$hmSessVars"
      [ "$PATH" = "bar:foo:baz:/existing" ] \
        || { echo "after first source: $PATH"; exit 1; }
      . "$TESTED/$hmSessVars"
      [ "$PATH" = "bar:foo:baz:/existing" ] \
        || { echo "after re-source: $PATH"; exit 1; }
    ) || fail "hm-session-vars.sh runtime semantics broken"
  '';
}
