{ realPkgs, ... }:

{
  home.sessionSearchVariables = {
    BOTH = [ "/hm/front" ];
    SHARED = [ "same" ];
  };
  home.sessionSearchVariablesAppend = {
    BOTH = [ "/hm/back" ];
    EMPTY = [ "" ];
    ONLY_APPEND = [
      "/fallback/one"
      "/fallback/two"
    ];
    SHARED = [ "same" ];
  };

  test.asserts.warnings.expected = [
    ''
      `home.sessionPath`, `home.sessionSearchVariables`, or
      `home.sessionSearchVariablesAppend` contains an empty entry, which Home
      Manager ignores. Write `.` to include the current directory. If the
      empty entry has tool-specific meaning, set the complete value through
      `home.sessionVariables` instead.
    ''
  ];

  nmt.script = ''
    hmSessVars=home-path/etc/profile.d/hm-session-vars.sh
    assertFileExists $hmSessVars

    for shellBin in \
      "$BASH" \
      ${realPkgs.dash}/bin/dash \
      "${realPkgs.zsh}/bin/zsh -f"; do

      env -u __HM_SESS_VARS_SOURCED -u __HM_SESS_VARS_MERGED \
        BOTH=/inherited \
        ONLY_APPEND=/inherited/append \
        SHARED=/inherited/shared \
        $shellBin -uc '
          . "$1"

          # On the first merge, the inherited value remains between them.
          [ "$BOTH" = "/hm/front:/inherited:/hm/back" ] \
            || { echo "BOTH: $BOTH"; exit 1; }
          [ "$ONLY_APPEND" = "/inherited/append:/fallback/one:/fallback/two" ] \
            || { echo "ONLY_APPEND: $ONLY_APPEND"; exit 1; }
          [ "$SHARED" = "/inherited/shared:same" ] \
            || { echo "SHARED: $SHARED"; exit 1; }
          exit 0
        ' shell "$TESTED/$hmSessVars" \
        || fail "$shellBin: append semantics broken"

      # An appended entry already present must not be duplicated or moved,
      # and a later source must stay idempotent.
      env -u __HM_SESS_VARS_SOURCED __HM_SESS_VARS_MERGED=1 \
        BOTH=/hm/back:/inherited \
        ONLY_APPEND=/fallback/two \
        SHARED=same:/inherited/shared \
        $shellBin -uc '
          . "$1"
          [ "$BOTH" = "/hm/front:/hm/back:/inherited" ] \
            || { echo "BOTH: $BOTH"; exit 1; }
          [ "$ONLY_APPEND" = "/fallback/two:/fallback/one" ] \
            || { echo "ONLY_APPEND: $ONLY_APPEND"; exit 1; }
          [ "$SHARED" = "same:/inherited/shared" ] \
            || { echo "SHARED: $SHARED"; exit 1; }
          before="$BOTH|$ONLY_APPEND|$SHARED"
          . "$1"
          [ "$BOTH|$ONLY_APPEND|$SHARED" = "$before" ] \
            || { echo "not idempotent: $BOTH|$ONLY_APPEND|$SHARED"; exit 1; }
          exit 0
        ' shell "$TESTED/$hmSessVars" \
        || fail "$shellBin: append was not idempotent"
    done
  '';
}
