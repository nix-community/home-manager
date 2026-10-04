{ config, realPkgs, ... }:

{
  # Keep this test to plain session variables. On Darwin the terminfo module
  # would otherwise add its TERMINFO_DIRS merge and TERM re-export here; both
  # are covered by tests/modules/targets-darwin/terminfo.nix.
  targets.darwin.terminfo.enable = false;

  home.sessionVariables = {
    V1 = "v1";
    V2 = "v2-${config.home.sessionVariables.V1}";
    IS_EMPTY = "";
    IS_NULL = null;
    IS_TRUE = true;
    IS_FALSE = false;
    WARNING = "$WARNING/suffix";
  };

  test.asserts.warnings.expected = [
    ''
      The following home.sessionVariables may change when applied again:

        WARNING, defined in `${toString ./session-variables.nix}'

      Home Manager applies the session variables file in each new shell,
      so these values can change repeatedly.

      For search paths, use home.sessionPath,
      home.sessionSearchVariables, or home.sessionSearchVariablesAppend.
      Those options add only the entries that are missing. For other
      variables, assign a complete value without referring to its previous
      contents.

      This check is best-effort and detects only direct parameter references
      such as $NAME, ''${NAME...}, and ''${#NAME}.
    ''
  ];

  # Keep the alias and heredoc top-level and verbatim. Wrapping delays alias
  # expansion, while indenting moves the heredoc terminator.
  home.sessionVariablesExtra = ''
    shopt -s expand_aliases 2>/dev/null || true
    alias hm_extra_alias='EXTRA_ALIAS_OK=1'
    hm_extra_alias
    export EXTRA_ALIAS_OK
    EXTRA_RUNS=$((''${EXTRA_RUNS:-0} + 1))
    export EXTRA_RUNS
    HEREDOC_OK=$(cat <<'EOT'
    verbatim
    EOT
    )
    export HEREDOC_OK
  '';

  nmt.script = ''
    hmSessVars=home-path/etc/profile.d/hm-session-vars.sh
    assertFileExists $hmSessVars

    for shellBin in \
      "$BASH" \
      ${realPkgs.dash}/bin/dash \
      "${realPkgs.zsh}/bin/zsh -f"; do

      env -u __HM_SESS_VARS_SOURCED -u __HM_SESS_VARS_MERGED \
        WARNING=base \
        $shellBin -uc '
          unset V1 V2 IS_EMPTY IS_NULL IS_TRUE IS_FALSE EXTRA_RUNS
          . "$1"

          [ "$V1" = v1 ] || { echo "V1: $V1"; exit 1; }
          [ "$V2" = v2-v1 ] || { echo "V2: $V2"; exit 1; }
          [ "$IS_EMPTY" = "" ] || { echo "IS_EMPTY: $IS_EMPTY"; exit 1; }
          [ "$IS_TRUE" = true ] || { echo "IS_TRUE: $IS_TRUE"; exit 1; }
          [ "$IS_FALSE" = false ] || { echo "IS_FALSE: $IS_FALSE"; exit 1; }
          [ "$WARNING" = base/suffix ] \
            || { echo "WARNING: $WARNING"; exit 1; }

          # A null value is skipped entirely rather than exported empty.
          [ -z "''${IS_NULL+set}" ] || { echo "IS_NULL was exported"; exit 1; }

          [ "$EXTRA_RUNS" = 1 ] || { echo "EXTRA_RUNS: $EXTRA_RUNS"; exit 1; }
          [ "$HEREDOC_OK" = verbatim ] \
            || { echo "HEREDOC_OK: <$HEREDOC_OK>"; exit 1; }
          [ "$EXTRA_ALIAS_OK" = 1 ] \
            || { echo "EXTRA_ALIAS_OK: <$EXTRA_ALIAS_OK>"; exit 1; }
          exit 0
        ' shell "$TESTED/$hmSessVars" \
        || fail "$shellBin: first source did not apply session variables"

      # The headline behaviour: a stale inherited value is replaced, while the
      # extra section stays once per session.
      env -u __HM_SESS_VARS_SOURCED -u __HM_SESS_VARS_MERGED \
        V1=stale V2=stale WARNING=base \
        $shellBin -uc '
          . "$1"
          [ "$V1" = v1 ] || { echo "stale V1 survived: $V1"; exit 1; }
          [ "$V2" = v2-v1 ] || { echo "stale V2 survived: $V2"; exit 1; }

          . "$1"
          [ "$V1" = v1 ] || { echo "V1 after re-source: $V1"; exit 1; }
          [ "$WARNING" = base/suffix/suffix ] \
            || { echo "WARNING after re-source: $WARNING"; exit 1; }
          [ "$EXTRA_RUNS" = 1 ] \
            || { echo "extra section ran again: $EXTRA_RUNS"; exit 1; }
          exit 0
        ' shell "$TESTED/$hmSessVars" \
        || fail "$shellBin: re-sourcing did not refresh session variables"

      # A child that inherits the sourced marker still refreshes plain values,
      # because only the extra section is guarded.
      env -u __HM_SESS_VARS_MERGED \
        __HM_SESS_VARS_SOURCED=1 V1=stale WARNING=base EXTRA_RUNS=1 \
        $shellBin -uc '
          . "$1"
          [ "$V1" = v1 ] || { echo "child kept stale V1: $V1"; exit 1; }
          [ "$WARNING" = base/suffix ] \
            || { echo "child WARNING: $WARNING"; exit 1; }
          [ "$EXTRA_RUNS" = 1 ] \
            || { echo "child re-ran the extra section: $EXTRA_RUNS"; exit 1; }
          exit 0
        ' shell "$TESTED/$hmSessVars" \
        || fail "$shellBin: inherited session did not refresh"
    done

    # Syntax check under a strict POSIX shell.
    ${realPkgs.dash}/bin/dash -n "$TESTED/$hmSessVars" \
      || fail "generated file is not valid POSIX sh"
  '';
}
