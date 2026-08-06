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
    TEST5 = [ "$TRAILING_NEWLINE_ENTRY" ];
    # Backslash escapes keep their double-quoted meaning: `\$` stays a
    # literal `$` (no expansion, safe under `set -u`) while `\\` is a
    # literal backslash that leaves the following `$HOME` expandable.
    TEST6 = [ "\\$LITERAL/entry" ];
    TEST7 = [ "\\\\$HOME/expanded" ];
  };

  nmt.script = ''
    hmSessVars=home-path/etc/profile.d/hm-session-vars.sh
    assertFileExists $hmSessVars

    # Exercise expansion, duplicates, empty entries, set -u, and re-sourcing.
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
        __hm_cur="keep-cur" \
        __hm_add="keep-add" \
        __hm_entry="keep-entry" \
        "$shell" -uc '
          unset TEST2 TEST3 TEST4 TEST6 TEST7 LITERAL
          TRAILING_NEWLINE_ENTRY=$(printf "line\n.")
          TRAILING_NEWLINE_ENTRY=''${TRAILING_NEWLINE_ENTRY%?}
          TEST5=tail
          . "$1"
          [ "$TEST4" = "/runtime/home:toolchain/bin:head/bin" ] \
            || { echo "TEST4 after first source: $TEST4"; exit 1; }
          [ "$TEST" = "bar:foo:baz" ] \
            || { echo "TEST after first source: $TEST"; exit 1; }
          [ "$TEST2" = "qux" ] \
            || { echo "TEST2 after first source: $TEST2"; exit 1; }
          [ "$TEST3" = "/runtime/home/tools" ] \
            || { echo "TEST3 after first source: $TEST3"; exit 1; }
          expectedTest5=$(printf "line\n:tail.")
          expectedTest5=''${expectedTest5%?}
          [ "$TEST5" = "$expectedTest5" ] \
            || { printf "TEST5 lost trailing newline: <%s>\n" "$TEST5"; exit 1; }
          [ "$TEST6" = "\$LITERAL/entry" ] \
            || { echo "TEST6 expanded an escaped dollar: $TEST6"; exit 1; }
          [ "$TEST7" = "\\/runtime/home/expanded" ] \
            || { echo "TEST7 lost the literal backslash: $TEST7"; exit 1; }
          [ "$__hm_cur" = keep-cur ] \
            || { echo "__hm_cur was clobbered: $__hm_cur"; exit 1; }
          [ "$__hm_add" = keep-add ] \
            || { echo "__hm_add was clobbered: $__hm_add"; exit 1; }
          [ "$__hm_entry" = keep-entry ] \
            || { echo "__hm_entry was clobbered: $__hm_entry"; exit 1; }
          . "$1"
          [ "$TEST" = "bar:foo:baz" ] \
            || { echo "TEST after re-source: $TEST"; exit 1; }
          [ "$TEST2" = "qux" ] \
            || { echo "TEST2 after re-source: $TEST2"; exit 1; }
          [ "$TEST3" = "/runtime/home/tools" ] \
            || { echo "TEST3 after re-source: $TEST3"; exit 1; }
          [ "$TEST5" = "$expectedTest5" ] \
            || { printf "TEST5 changed after re-source: <%s>\n" "$TEST5"; exit 1; }
          [ "$TEST6" = "\$LITERAL/entry" ] \
            || { echo "TEST6 changed after re-source: $TEST6"; exit 1; }
          [ "$TEST7" = "\\/runtime/home/expanded" ] \
            || { echo "TEST7 changed after re-source: $TEST7"; exit 1; }
          [ "$__hm_cur:$__hm_add:$__hm_entry" = keep-cur:keep-add:keep-entry ] \
            || { echo "scratch globals changed after re-source"; exit 1; }
        ' shell "$TESTED/$hmSessVars" \
        || fail "$shell: hm-session-vars.sh search variable semantics broken"

      # A variable that is set but not exported must still be exported, even
      # when it already contains every configured entry and nothing is added.
      TERM="dumb" \
        TERMINFO_DIRS="" \
        EMPTY_ENTRY="" \
        HOME="/runtime/home" \
        "$shell" -uc '
          unset TEST TEST2 TEST3 TEST4 TEST5
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
