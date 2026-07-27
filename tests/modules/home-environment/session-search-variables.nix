{ realPkgs, ... }:

{
  home.sessionSearchVariables = {
    TEST = [
      "bar"
      "baz"
      "bar"
      ""
      "$EMPTY_ENTRY"
      "foo"
      ""
    ];
    TEST2 = [ "qux" ];
    TEST3 = [ "$HOME/tools" ];
    # A bare `$VAR` followed by an entry starting with a zsh history-style
    # modifier letter. Joining these into one quoted string makes zsh parse
    # `$HOME:t` as the `tail` modifier and silently corrupt the value.
    TEST4 = [
      "$HOME"
      "toolchain/bin"
      "head/bin"
    ];
  };

  nmt.script = ''
    hmSessVars=home-path/etc/profile.d/hm-session-vars.sh
    assertFileExists $hmSessVars
    assertFileContains $hmSessVars \
      '__hm_entry="bar"'
    assertFileContains $hmSessVars \
      '__hm_entry="baz"'
    assertFileContains $hmSessVars \
      '__hm_entry="bar"'
    assertFileContains $hmSessVars \
      '__hm_entry=""'
    assertFileContains $hmSessVars \
      '__hm_entry="$EMPTY_ENTRY"'
    assertFileContains $hmSessVars \
      '__hm_entry="foo"'
    assertFileContains $hmSessVars \
      '__hm_entry=""'
    assertFileContains $hmSessVars \
      '__hm_cur="''${TEST-}"'
    assertFileContains $hmSessVars \
      '  __hm_cur="$__hm_add''${__hm_cur:+:}$__hm_cur"'
    assertFileContains $hmSessVars \
      'export TEST="$__hm_cur"'
    assertFileContains $hmSessVars \
      '__hm_entry="qux"'
    assertFileContains $hmSessVars \
      '__hm_cur="''${TEST2-}"'
    assertFileContains $hmSessVars \
      '__hm_entry="$HOME/tools"'
    assertFileContains $hmSessVars \
      '__hm_cur="''${TEST3-}"'

    # Multiple blocks must not leak scratch state. Exercise runtime expansion,
    # duplicate/empty candidates, set -u, and re-sourcing under each supported
    # Bourne-style shell.
    # NMT supplies Bash itself. dash and zsh must come from realPkgs because
    # normal test packages are deliberately scrubbed to non-runnable paths.
    for shell in \
      "$BASH" \
      ${realPkgs.dash}/bin/dash \
      ${realPkgs.zsh}/bin/zsh; do
      TERM="dumb" \
        TERMINFO_DIRS="" \
        EMPTY_ENTRY="" \
        HOME="/runtime/home" \
        TEST="baz" \
        "$shell" -uc '
          unset TEST2 TEST3 TEST4
          . "$1"
          [ "$TEST4" = "/runtime/home:toolchain/bin:head/bin" ] \
            || { echo "TEST4 after first source: $TEST4"; exit 1; }
          [ "$TEST" = "bar:foo:baz" ] \
            || { echo "TEST after first source: $TEST"; exit 1; }
          [ "$TEST2" = "qux" ] \
            || { echo "TEST2 after first source: $TEST2"; exit 1; }
          [ "$TEST3" = "/runtime/home/tools" ] \
            || { echo "TEST3 after first source: $TEST3"; exit 1; }
          . "$1"
          [ "$TEST" = "bar:foo:baz" ] \
            || { echo "TEST after re-source: $TEST"; exit 1; }
          [ "$TEST2" = "qux" ] \
            || { echo "TEST2 after re-source: $TEST2"; exit 1; }
          [ "$TEST3" = "/runtime/home/tools" ] \
            || { echo "TEST3 after re-source: $TEST3"; exit 1; }
        ' shell "$TESTED/$hmSessVars" \
        || fail "$shell: hm-session-vars.sh search variable semantics broken"

      # A variable that is set but not exported must still be exported, even
      # when it already contains every configured entry and nothing is added.
      TERM="dumb" \
        TERMINFO_DIRS="" \
        EMPTY_ENTRY="" \
        HOME="/runtime/home" \
        "$shell" -uc '
          unset TEST TEST2 TEST3 TEST4
          TEST2=qux
          . "$1"
          [ "$TEST2" = "qux" ] \
            || { echo "TEST2 value: $TEST2"; exit 1; }
          env | grep -qx "TEST2=qux" \
            || { echo "TEST2 was not exported"; exit 1; }
        ' shell "$TESTED/$hmSessVars" \
        || fail "$shell: hm-session-vars.sh left a complete variable unexported"
    done
  '';
}
