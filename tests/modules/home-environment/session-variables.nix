{ config, ... }:

{
  home.sessionVariables = {
    V1 = "v1";
    V2 = "v2-${config.home.sessionVariables.V1}";
    IS_EMPTY = "";
    IS_NULL = null;
    IS_TRUE = true;
    IS_FALSE = false;
  };

  # Deliberately no trailing newline; the generated file must not glue the
  # closing `fi` onto this line.
  home.sessionVariablesExtra = "export EXTRA_ONCE=extra-once";

  nmt.script = ''
    sessionVars=home-path/etc/profile.d/hm-session-vars.sh
    assertFileExists "$sessionVars"
    assertFileContains "$sessionVars" 'case " ''${__HM_SESS_VARS_SKIP-} " in'
    assertFileNotRegex "$sessionVars" 'export IS_NULL='

    "$BASH" -n "$TESTED/$sessionVars" \
      || fail "hm-session-vars.sh has a syntax error"

    (
      export V1=stale V2=stale
      export __HM_SESS_VARS_SKIP=" V1 "
      unset __HM_SESS_VARS_SOURCED EXTRA_ONCE
      . "$TESTED/$sessionVars"
      [ "$V1" = stale ] || exit 1
      [ "$V2" = v2-v1 ] || exit 1
      [ "$IS_EMPTY" = "" ] || exit 1
      [ "$IS_FALSE" = false ] || exit 1
      [ "$IS_TRUE" = true ] || exit 1
      [ "$EXTRA_ONCE" = extra-once ] || exit 1
    ) || fail "session variable refresh or skip manifest failed"
  '';
}
