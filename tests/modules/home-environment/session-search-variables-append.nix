{ realPkgs, ... }:

{
  # Prepend and append contributions to the same variable must compose:
  # prepended entries land in front, appended ones behind whatever the
  # environment already had.
  home.sessionSearchVariables.TEST = [ "front" ];
  home.sessionSearchVariablesAppend = {
    TEST = [ "back" ];
    TEST2 = [
      "tail"
      "tail"
      ""
      "$EMPTY_ENTRY"
      "tail2"
    ];
    TEST3 = [ "$HOME/fallback" ];
  };

  nmt.script = ''
    hmSessVars=home-path/etc/profile.d/hm-session-vars.sh
    assertFileExists $hmSessVars

    for shell in \
      "$BASH" \
      ${realPkgs.dash}/bin/dash \
      ${realPkgs.zsh}/bin/zsh; do
      TERM="dumb" \
        TERMINFO_DIRS="" \
        EMPTY_ENTRY="" \
        HOME="/runtime/home" \
        TEST="inherited" \
        "$shell" -uc '
          unset TEST2 TEST3
          . "$1"
          # front prepended, back appended, inherited entry keeps its place
          [ "$TEST" = "front:inherited:back" ] \
            || { echo "TEST after first source: $TEST"; exit 1; }
          # duplicate and empty candidates collapse to one occurrence each
          [ "$TEST2" = "tail:tail2" ] \
            || { echo "TEST2 after first source: $TEST2"; exit 1; }
          [ "$TEST3" = "/runtime/home/fallback" ] \
            || { echo "TEST3 after first source: $TEST3"; exit 1; }
          . "$1"
          [ "$TEST" = "front:inherited:back" ] \
            || { echo "TEST after re-source: $TEST"; exit 1; }
          [ "$TEST2" = "tail:tail2" ] \
            || { echo "TEST2 after re-source: $TEST2"; exit 1; }
          [ "$TEST3" = "/runtime/home/fallback" ] \
            || { echo "TEST3 after re-source: $TEST3"; exit 1; }
        ' shell "$TESTED/$hmSessVars" \
        || fail "$shell: append semantics broken"

      # An already-complete variable must still be exported, and an entry that
      # is already present must not be moved to the end.
      TERM="dumb" \
        TERMINFO_DIRS="" \
        EMPTY_ENTRY="" \
        HOME="/runtime/home" \
        "$shell" -uc '
          unset TEST TEST2 TEST3
          TEST2=tail2:other:tail
          . "$1"
          [ "$TEST2" = "tail2:other:tail" ] \
            || { echo "TEST2 was reordered: $TEST2"; exit 1; }
          env | grep -qx "TEST2=tail2:other:tail" \
            || { echo "TEST2 was not exported"; exit 1; }
        ' shell "$TESTED/$hmSessVars" \
        || fail "$shell: append reordered or failed to export a complete variable"
    done
  '';
}
